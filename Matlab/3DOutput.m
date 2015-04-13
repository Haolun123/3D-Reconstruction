%
clear;
close all;

%
X_Axis=0;
Y_Axis=1;

%%

pathName = '';
baseFileName_01 = 'Capture';

imgType = '.bmp';
stepNum01=4;

%Choose ONLY ONE fringe direction: X_Axis or Y_Axis;
Fringe_Direction=X_Axis;%X_Axis: Horizontal
%Fringe_Direction=Y_Axis;%Y_Axis: Vertical


%%

shiftedPhase01 = 2*pi/stepNum01;


        for i = 1:stepNum01;
            
            img2Read = strcat(pathName,baseFileName_01,num2str(i,'%02d'),imgType);
            eval([ 'j' ' = imread(img2Read);']);
          eval([ 'img01_' num2str(i,'%02d') '=double(j(:,:,1));']);
            
        end;
          
        size_img_read = size(img01_01);
        resY = size_img_read(1);
        resX = size_img_read(2);

%%
%Phase Retrieval
        
        sinTerm01 = zeros(resY,resX);
        cosTerm01 = zeros(resY,resX);
        
        for i = 1:stepNum01;
            
            eval(['sinTerm01 = sinTerm01 + img01_' num2str(i,'%02d') ' * sin(shiftedPhase01 * i) ;' ]);
            eval(['cosTerm01 = cosTerm01 + img01_' num2str(i,'%02d') ' * cos(shiftedPhase01 * i) ;' ]);           
            
        end;

        phase_Wrapped01 = atan2(sinTerm01,cosTerm01);
        
        modulation01 = (2/stepNum01) * sqrt(sinTerm01.^2+cosTerm01.^2);
 
        figHandle = figure;
        set(figHandle, 'name','Phase_Wrapped');
        imshow(phase_Wrapped01(:,:),[]),title('Phase_Wrapped');
        
     
R=phase_Wrapped01;        
x=2*pi;
T=mygraycodex;
XT=mygraycodex;
for i=1:resX;
    for j=1:resY-1;
        if T(j,i)==T(j+1,i)&&R(j+1,i)-R(j,i)>=pi;
            T(j+1,i)=T(j+1,i)-1;
        else if T(j,i)==T(j+1,i)+1&&R(j+1,i)-R(j,i)<pi;
                T(j+1,i)=T(j+1,i)+1;
            else if T(j,i)==T(j+1,i)-1;
                    T(j+1,i)=T(j,i);
                end;
            end;
        end;
    end;
end;
phase=phase_Wrapped01+x*T;
Uplate=phaseplate;
phase1=phase-phaseplate;
NA=(phase1(400:700,440:800)-12.026)/2+12.026;
XYZ=1/800+(2*pi*208*400/3270)./(800*NA);
XYZ=1./XYZ;
figHandle = figure;
        set(figHandle, 'name','Phase');
        imshow(phase(:,:),[]),title('Phase');
        figHandle = figure;
        set(figHandle, 'name','Phase');
        imshow(phase1(400:700,300:880),[]),title('Phase');
        figure;surfl(XYZ,'light'); SHADING INTERP;colormap('gray');view(180,80);
        figure;mesh(NA); SHADING INTERP;view(180,90);zlabel('相位/rad');xlabel('横向像素/pixel');ylabel('纵向像素/pixel');
        figure;mesh(XYZ); SHADING INTERP;view(180,90);zlabel('高度/mm');xlabel('横向像素/pixel');ylabel('纵向像素/pixel');
XYZ=XYZ-56;
 figure;mesh(XYZ(250:300,:)); SHADING INTERP;view(180,90);zlabel('高度/mm');xlabel('横向像素/pixel');ylabel('纵向像素/pixel');
       f=phase1;
        f=fft2(f);
        

f=fftshift(f);

[m,n]=size(f); %

d0=80;

m1=fix(m/2);

n1=fix(n/2);

for i=1:m

    for j=1:n

        d=sqrt((i-m1)^2+(j-n1)^2);

        h(i,j)=exp(-d^2/2/d0^2);

    end

end

g=f.*h;

g=ifftshift(g);

g=ifft2(g);

g=real(g); 
imshow(g(300:700,400:900),[]),title('Phase');
        figure;surfl(g(300:700,400:900),'light'); SHADING INTERP;colormap('gray');view(180,80);
       
        figure;mesh(g(300:700,400:900)); SHADING INTERP;view(180,90);      