#include "stdafx.h"
#include "stdlib.h"
#include "time.h"
#include "math.h"
#include "stdio.h"
#include "string.h"
#include "windows.h"
#include "vector"
#include "GL/glut.h"
#include "iostream"
#include "fstream"

using std::vector;
using std::string;
using std::cout;
//using std::cin;
using std::endl;
#define PI 3.1415926535  

struct pointposition
{
	double x;
	double y;
	double z;
};
float thetaX = 0.0, thetaY = 0.0, scaleFactor = 0.005;
static float dx = 0, dy = 0, oldy = -1, oldx = -1;
int width = 300, height = 300;       //set window size

vector<pointposition> data;
vector<float> ptsmm;
pointposition ptsCen = {};             //point cloud center
void drawCloud()
{
	glPointSize(1.0f);
	glColor3f(0.6, 0.6, 0.6);    //point cloud with grey color
	glBegin(GL_POINTS);
	for (int i = 0; i < 200000; i++)
	{
		glVertex3f(data[i].x-250, data[i].y-200, data[i].z);
	}
	glEnd();
	glPointSize(5.0f);
	glColor3f(1.0, 0.0, 0.0);    //red center point
	glBegin(GL_POINTS);
	glVertex3f(250,200,40);
	glEnd();
}
void init(void)
{
	glClearColor(0.0, 0.0, 0.0, 0.0);     //set bakground color
	glShadeModel(GL_FLAT);
}
void display()
{
	glClear(GL_COLOR_BUFFER_BIT);
	if (thetaY<0)
	{
		thetaY = thetaY + 360;
	}
	if (thetaY>360)
	{
		thetaY = thetaY - 360;
	}
	if (thetaX<0)
	{
		thetaX = thetaX + 360;
	}
	if (thetaX>360)
	{
		thetaX = thetaX - 360;
	}
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	gluLookAt(0, 0, 2, 0.0, 0.0, 0.0, 0.0, -1.0, 0.0);      //set position
	//glTranslatef(ptsCen.x,ptsCen.y,ptsCen.z);
	glRotatef(thetaX, 1, 0, 0);
	glRotatef(thetaY, 0, 1, 0);
	glScalef(scaleFactor, scaleFactor, scaleFactor);
	glTranslatef(-ptsCen.x, -ptsCen.y, -ptsCen.z);
	drawCloud();
	glutSwapBuffers();
}
void reshape(int width, int height)
{
	glViewport(0, 0, (GLsizei)width, (GLsizei)height);
	glMatrixMode(GL_PROJECTION);         //projection transformation, determine the size of display space
	glLoadIdentity();
	glOrtho(-1.5, 1.5, -1.5, 1.5, -5, 5);
}
void keyBoard(unsigned char key, int x, int y)
{
	switch (key)
	{
	case 'A':              //amplification and deflation
	case 'a':
		scaleFactor *= 0.9;
		glutPostRedisplay();
		break;
	case 'D':
	case 'd':
		scaleFactor *= 1.1;
		glutPostRedisplay();
		break;
	case 'R':                     //reset
	case 'r':
		thetaX = 0;
		thetaY = 0;
		scaleFactor = 1.0;
		glutPostRedisplay();
		break;
	case 'Q':                    //quit
	case 'q':
		exit(0);
		break;
	default:
		break;
	}
}
void myMouse(int button, int state, int x, int y)        //deal with a mouse click 
{
	if (state == GLUT_DOWN && button == GLUT_LEFT_BUTTON)                  //left click and recording initial coordinates
		oldx = x, oldy = y;
	if (state == GLUT_DOWN && button == GLUT_RIGHT_BUTTON)             //right click and reset
	{
		thetaX = 0; thetaY = 0; scaleFactor = 1;
		glutPostRedisplay();
	}
	if (state == GLUT_DOWN && button == GLUT_MIDDLE_BUTTON)
	{
	}
}
void onMouseMove(int x, int y)     //deal with a mouse moving
{
	dx += x - oldx;
	dy += y - oldy;
	thetaX = dy / width * 90;
	thetaY = dx / width * 90;
	oldx = x, oldy = y;               
	glutPostRedisplay();
}


//////////////////////////////////

void calminmax(vector<float> & ptsmm, vector<pointposition> pts);

int _tmain(int argc, char ** argv)
{
	std::ifstream f("out.txt");
	if (!f)
	{
		cout << "cannot read file!!" << endl;
		getchar();
	}
	pointposition temp = {};
	while (!f.eof())
	{
		f >> temp.x;
		f >> temp.y;
		f >> temp.z;
		temp.z = (temp.z + 5) * 10;
		data.push_back(temp);
	}

	calminmax(ptsmm, data);
	float  width = ptsmm[0] - ptsmm[1];
	float height = ptsmm[2] - ptsmm[3];
	float depth = ptsmm[4] - ptsmm[5];
	int dataLength = data.size();
	ptsCen.x = (ptsmm[0] + ptsmm[1]) / 2; ptsCen.x = (ptsmm[2] + ptsmm[3]) / 2; ptsCen.x = (ptsmm[4] + ptsmm[5]) / 2;
	cout << "Points Number: " << dataLength << endl << "depth: " << depth << endl << "height: " << height << endl << "width: " << width << endl;
	cout << "Space scope: " << endl << "x: " << ptsmm[1] << "  " << ptsmm[0] << endl << "y: " << ptsmm[3] << "  " << ptsmm[2] << endl << "z: " << ptsmm[5] << "  " << ptsmm[4] << endl;

	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
	glutInitWindowSize(600, 600);
	glutCreateWindow("PointCloud Display");
	glutReshapeFunc(reshape);
	glutDisplayFunc(&display);
	glutKeyboardFunc(keyBoard);
	init();
	glutMouseFunc(myMouse);
	glutMotionFunc(onMouseMove);
	glutMainLoop();
	return 0;
}

void calminmax(vector<float> & ptsmm, vector<pointposition> data)     //caculate the max and min of x,y,z
{
	int i, j;
	float tmax, tmin;
	float ** a;
	a = new float *[3];
	for (i = 0; i<3; i++)
	{
		a[i] = new float[data.size()];
	}
	for (i = 0; i <= 200000; i++)
	{
		a[0][i] = data[i].x;
		a[1][i] = data[i].y;
		a[2][i] = data[i].z;
	}
	for (i = 0; i<3; i++)
	{
		tmax = a[i][0];
		tmin = a[i][0];
		for (j = 0; j <= 5; j++)
		{
			if (a[i][j]>tmax)
			{
				tmax = a[i][j];
			}
			if (a[i][j] <= tmin)
			{
				tmin = a[i][j];
			}

		}
		ptsmm.push_back(tmax);
		ptsmm.push_back(tmin);
	}

	for (int i = 0; i<3; i++)    //free memory inside out
	{
		delete[]a[i];
		a[i] = NULL;
	}
	delete[]a;
	a = NULL;
}