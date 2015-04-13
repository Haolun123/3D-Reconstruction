#include <stdio.h>
#include "cuda.h"
#include "cublas.h"
#include <vector>
#include <opencv2/opencv.hpp>
#include <iostream>
#include <fstream>
#include <math.h>
#define pi 3.1415926535
using namespace cv;
using std::cout;
using std::endl;


__global__ void binarykernel(uchar *dinput1,uchar *dinput2, uchar *dinput3, uchar *dinput4, uchar *dinput5,double doutbinary1[][1024],double doutbinary2[][1024],double doutbinary3[][1024],double doutbinary4[][1024],double doutbinary5[][1024] )
{
	int labelx = (blockIdx.x * blockDim.x + threadIdx.x);
	int labely = (blockIdx.y * blockDim.y + threadIdx.y);
	double p1 = dinput1[1280*labely+labelx];
	doutbinary1[labelx][labely]=(p1 > 255*0.3) ? 1 : 0;
	double p2 = dinput2[1280*labely+labelx];
	doutbinary2[labelx][labely]=(p2> 255*0.3) ? 1 : 0;
	double p3 = dinput3[1280*labely+labelx];
	doutbinary3[labelx][labely]=(p3 > 255*0.3) ? 1 : 0;
	double p4 = dinput4[1280*labely+labelx];
	doutbinary4[labelx][labely]=(p4 > 255*0.3) ? 1 : 0;
	double p5 = dinput5[1280*labely+labelx];
	doutbinary5[labelx][labely]=(p5 > 255*0.3) ? 1 : 0;
}
__global__ void phasewrapkernel(uchar *dph1, uchar *dph2, uchar *dph3, uchar *dph4, double dphasewrap[][1024])
{
	int labelx = (blockIdx.x * blockDim.x + threadIdx.x);
	int labely = (blockIdx.y * blockDim.y + threadIdx.y);
	double doutputsin = 0;
	double doutputcos = 0;
	dphasewrap[labelx][labely] = 0;
	double p1 = dph1[1280*labely+labelx];
	doutputsin += p1*sin(pi/2);
	doutputcos += p1*cos(pi/2);
	double p2 = dph2[1280*labely+labelx];
	doutputsin += p2*sin(2*pi/2);
	doutputcos += p2*cos(2*pi/2);
	double p3 = dph3[1280*labely+labelx];
	doutputsin += p3*sin(3*pi/2);
	doutputcos += p3*cos(3*pi/2);
	double p4 = dph4[1280*labely+labelx];
	doutputsin += p4*sin(4*pi/2);
	doutputcos += p4*cos(4*pi/2);
	dphasewrap[labelx][labely] = atan2(doutputsin,doutputcos);
}
__global__ void graykernel(double dG1[][1024],double dG2[][1024],double dG3[][1024],double dG4[][1024],double dG5[][1024],double dgraycode[][1024])
{
	int labelx = (blockIdx.x * blockDim.x + threadIdx.x);
	int labely = (blockIdx.y * blockDim.y + threadIdx.y);
	int gray1 = dG1[labelx][labely];
	int gray2 = dG2[labelx][labely];
	int gray3 = dG3[labelx][labely];
	int gray4 = dG4[labelx][labely];
	int gray5 = dG5[labelx][labely];
	dgraycode[labelx][labely] = gray1*16+(gray1^gray2)*8+((gray1^gray2)^gray3)*4+(((gray1^gray2)^gray3)^gray4)*2+(((gray1^gray2)^gray3)^gray4)^gray5;
}
 __global__ void constructimgkernel(double doutbinary1[][1024],double doutbinary2[][1024],double doutbinary3[][1024],double doutbinary4[][1024],double doutbinary5[][1024] )
{
	int labelx = (blockIdx.x * blockDim.x + threadIdx.x);
	int labely = (blockIdx.y * blockDim.y + threadIdx.y);
	double objphase = doutbinary1[labelx][labely];
	double objgray = doutbinary2[labelx][labely];
	double platephase = doutbinary3[labelx][labely];
	double plategray = doutbinary4[labelx][labely];
	doutbinary5[labelx][labely] = objphase+objgray*2*pi-platephase-plategray*2*pi;
}
__global__ void MedianFilter(double In[][1024],double Out[][1024])  
{  
    double window[9];  
    int x = (blockIdx.x * blockDim.x + threadIdx.x);
	int y = (blockIdx.y * blockDim.y + threadIdx.y);  
    if(x>= 1280 && y>= 1024) return;  
    window[0]=(y==0||x==0)?0:In[x-1][y-1];  
    window[1]=(y==0)?0:In[x][y-1];  
    window[2]=(y==0||x==1279)? 0:In[x+1][y-1];  
    window[3]=(x==0)? 0:In[x-1][y];  
    window[4]= In[x][y];  
    window[5]=(x==1279)? 0:In[x+1][y];  
    window[6]=(y==1023||x==0)? 0:In[x-1][y+1];  
    window[7]=(y==1023)? 0:In[x][y+1];  
    window[8]=(y==1023||x==1279)? 0:In[x+1][y+1];  
    for (unsigned int j=0; j<5; ++j)  
    {  
        int min=j;  
        for (unsigned int l=j+1; l<9; ++l)  
            if (window[l] < window[min])  
                min=l;  
        double temp=window[j];  
        window[j]=window[min];  
        window[min]=temp;  
    }  
    Out[x][y]=window[4];  
}
int main()
{
	int i=0,j=0;
	Mat *objectgray=new Mat[5];
	Mat *plategray=new Mat[5];
	Mat *objectphase=new Mat[4];
	Mat *platephase=new Mat[4];
	dim3 grid( 64, 64 ), threads( 20, 16 );
	
	for(i=0;i<5;i++){  
		objectgray[i] = imread( format( "Capture%d.bmp",i+1),0); 
		plategray[i] = imread( format( "grayplate%d.bmp",i+1),0);
	}
	uchar *objectgray1 = objectgray[0].data;
	uchar *objectgray2 = objectgray[1].data;
	uchar *objectgray3 = objectgray[2].data;
	uchar *objectgray4 = objectgray[3].data;
	uchar *objectgray5 = objectgray[4].data;
	uchar *plategray1 = plategray[0].data;
	uchar *plategray2 = plategray[1].data;
	uchar *plategray3 = plategray[2].data;
	uchar *plategray4 = plategray[3].data;
	uchar *plategray5 = plategray[4].data;
	double (*objectbw1)[1024] = new double[1280][1024];
	double (*objectbw2)[1024] = new double[1280][1024];
	double (*objectbw3)[1024] = new double[1280][1024];
	double (*objectbw4)[1024] = new double[1280][1024];
	double (*objectbw5)[1024] = new double[1280][1024];
	double (*platebw1)[1024] = new double[1280][1024];
	double (*platebw2)[1024] = new double[1280][1024];
	double (*platebw3)[1024] = new double[1280][1024];
	double (*platebw4)[1024] = new double[1280][1024];
	double (*platebw5)[1024] = new double[1280][1024];
	double (*graycodeobject)[1024] = new double[1280][1024];
	double (*graycodeplate)[1024] = new double[1280][1024];
	uchar *dinput1,*dinput2,*dinput3,*dinput4,*dinput5;
	double (*doutbinary1)[1024],(*doutbinary2)[1024],(*doutbinary3)[1024],(*doutbinary4)[1024],(*doutbinary5)[1024];
	double (*dgraycode)[1024];
	cudaMalloc((void**)&dinput1,1280*1024*sizeof(uchar));
	cudaMalloc((void**)&dinput2,1280*1024*sizeof(uchar));
	cudaMalloc((void**)&dinput3,1280*1024*sizeof(uchar));
	cudaMalloc((void**)&dinput4,1280*1024*sizeof(uchar));
	cudaMalloc((void**)&dinput5,1280*1024*sizeof(uchar));
	cudaMalloc((void**)&doutbinary1,1280*1024*sizeof(double));
	cudaMalloc((void**)&doutbinary2,1280*1024*sizeof(double));
	cudaMalloc((void**)&doutbinary3,1280*1024*sizeof(double));
	cudaMalloc((void**)&doutbinary4,1280*1024*sizeof(double));
	cudaMalloc((void**)&doutbinary5,1280*1024*sizeof(double));
	cudaMalloc((void**)&dgraycode,1280*1024*sizeof(double));
	cudaMemcpy( dinput1, objectgray1, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dinput2, objectgray2, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dinput3, objectgray3, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dinput4, objectgray4, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dinput5, objectgray5, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	binarykernel<<<grid, threads>>>(dinput1,dinput2,dinput3,dinput4,dinput5,doutbinary1,doutbinary2,doutbinary3,doutbinary4,doutbinary5);
	graykernel<<<grid, threads>>>(doutbinary1,doutbinary2,doutbinary3,doutbinary4,doutbinary5,dgraycode);
	cudaMemcpy( graycodeobject, dgraycode, 1280*1024*sizeof(double), cudaMemcpyDeviceToHost ) ;
	
	cudaMemcpy( dinput1, plategray1, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dinput2, plategray2, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dinput3, plategray3, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dinput4, plategray4, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dinput5, plategray5, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	binarykernel<<<grid, threads>>>(dinput1,dinput2,dinput3,dinput4,dinput5,doutbinary1,doutbinary2,doutbinary3,doutbinary4,doutbinary5);
	graykernel<<<grid, threads>>>(doutbinary1,doutbinary2,doutbinary3,doutbinary4,doutbinary5,dgraycode);
	cudaMemcpy( graycodeplate, dgraycode, 1280*1024*sizeof(double), cudaMemcpyDeviceToHost  );
	cudaFree(dinput1);
	cudaFree(dinput2);
	cudaFree(dinput3);
	cudaFree(dinput4);
	cudaFree(dinput5);
	cudaFree(doutbinary1);
	cudaFree(doutbinary2);
	cudaFree(doutbinary3);
	cudaFree(doutbinary4);
	cudaFree(doutbinary5);
	cudaFree(dgraycode);
	for(j=0;j<4;j++){
		objectphase[j] = imread( format( "Capture0%d.bmp",j+1),0); 
		platephase[j] = imread( format( "plate%d.bmp",j+1),0);
	}
	uchar *objphase1 = objectphase[0].data;
	uchar *objphase2 = objectphase[1].data;
	uchar *objphase3 = objectphase[2].data;
	uchar *objphase4 = objectphase[3].data;
	uchar *platephase1 = platephase[0].data;
	uchar *platephase2 = platephase[1].data;
	uchar *platephase3 = platephase[2].data;
	uchar *platephase4 = platephase[3].data;
	double (*objphasewrap)[1024] = new double[1280][1024];
	double (*platephasewrap)[1024] = new double[1280][1024];
	uchar *dph1,*dph2,*dph3,*dph4;
	double (*dphasewrap)[1024];
	cudaMalloc((void**)&dph1,1280*1024*sizeof(uchar));
	cudaMalloc((void**)&dph2,1280*1024*sizeof(uchar));
	cudaMalloc((void**)&dph3,1280*1024*sizeof(uchar));
	cudaMalloc((void**)&dph4,1280*1024*sizeof(uchar));
	cudaMalloc((void**)&dphasewrap,1280*1024*sizeof(double));
	cudaMemcpy( dph1, objphase1, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dph2, objphase2, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dph3, objphase3, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dph4, objphase4, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	phasewrapkernel<<<grid, threads>>>(dph1,dph2,dph3,dph4,dphasewrap);
	cudaMemcpy( objphasewrap, dphasewrap, 1280*1024*sizeof(double), cudaMemcpyDeviceToHost ) ;

	cudaMemcpy( dph1, platephase1, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dph2, platephase2, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dph3, platephase3, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( dph4, platephase4, 1280*1024*sizeof(uchar), cudaMemcpyHostToDevice ) ;
	phasewrapkernel<<<grid, threads>>>(dph1,dph2,dph3,dph4,dphasewrap);
	cudaMemcpy( platephasewrap, dphasewrap, 1280*1024*sizeof(double), cudaMemcpyDeviceToHost ) ;
	cudaFree(dph1);
	cudaFree(dph2);
	cudaFree(dph3);
	cudaFree(dph4);
	cudaFree(dphasewrap);
		
	for (i=0;i<1280;i++){
		for (j=0;j<1023;j++){
			if ((graycodeobject[i][j]==graycodeobject[i][j+1])&&(objphasewrap[i][j+1]-objphasewrap[i][j]>=pi))
				graycodeobject[i][j+1]=graycodeobject[i][j+1]-1;
			else if ((graycodeobject[i][j]==graycodeobject[i][j+1]+1)&&(objphasewrap[i][j+1]-objphasewrap[i][j]<pi))
					graycodeobject[i][j+1]=graycodeobject[i][j+1]+1;
				else if (graycodeobject[i][j]==graycodeobject[i][j+1]-1)
						graycodeobject[i][j+1]=graycodeobject[i][j];
		}
	}
	for (i=0;i<1280;i++){
		for (j=0;j<1023;j++){
			if ((graycodeplate[i][j]==graycodeplate[i][j+1])&&(platephasewrap[i][j+1]-platephasewrap[i][j]>=pi))
				graycodeplate[i][j+1]=graycodeplate[i][j+1]-1;
			else if ((graycodeplate[i][j]==graycodeplate[i][j+1]+1)&&(platephasewrap[i][j+1]-platephasewrap[i][j]<pi))
					graycodeplate[i][j+1]=graycodeplate[i][j+1]+1;
				else if (graycodeplate[i][j]==graycodeplate[i][j+1]-1)
						graycodeplate[i][j+1]=graycodeplate[i][j];
		}
	}	
	double (*imgoutput)[1024] = new double[1280][1024];
	double (*imgafterfilter)[1024] = new double[1280][1024];
	cudaMalloc((void**)&doutbinary1,1280*1024*sizeof(double));
	cudaMalloc((void**)&doutbinary2,1280*1024*sizeof(double));
	cudaMalloc((void**)&doutbinary3,1280*1024*sizeof(double));
	cudaMalloc((void**)&doutbinary4,1280*1024*sizeof(double));
	cudaMalloc((void**)&doutbinary5,1280*1024*sizeof(double));
	cudaMemcpy( doutbinary1, objphasewrap,  1280*1024*sizeof(double), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( doutbinary2, graycodeobject,  1280*1024*sizeof(double), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( doutbinary3, platephasewrap,  1280*1024*sizeof(double), cudaMemcpyHostToDevice ) ;
	cudaMemcpy( doutbinary4, graycodeplate,  1280*1024*sizeof(double), cudaMemcpyHostToDevice ) ;
	constructimgkernel<<<grid, threads>>>(doutbinary1,doutbinary2,doutbinary3,doutbinary4,doutbinary5);
	cudaMemcpy( imgoutput, doutbinary5,  1280*1024*sizeof(double), cudaMemcpyDeviceToHost ) ;
	cudaFree(doutbinary2);
	cudaFree(doutbinary3);
	cudaFree(doutbinary4);
	MedianFilter<<<grid, threads>>>(doutbinary5,doutbinary1);
	cudaMemcpy( imgafterfilter, doutbinary1,  1280*1024*sizeof(double), cudaMemcpyDeviceToHost ) ;
	cudaFree(doutbinary1);
	cudaFree(doutbinary5);
	std::ofstream outf("out.txt",std::ios::out);
   
	for (i=300;i<700;i++){
		for (j=400;j<900;j++){
			double z=imgafterfilter[j][i];
			outf<<j-400<<" "<<i-300<<" "<<z<<endl;
		}
	}
	outf.close();
	
}

