//g++ -O2 -o main main.cpp
#include <iostream>
#include <string>
#include <time.h> 
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */      
#include <vector>
#include <cstdlib>
#include <math.h>
#include <cstdio>


#include "Body.h"
#include "StartSimulation.h"
#include <GL/glut.h>


#define GRIDSIDES 1000

#define NUMBODY 2000  //number of stars generated

#define MAXMASS 200 // max mass a body cna get
#define GalaxyX 1200 //0 to boundry
#define GalaxyY 1000 // 0 to boundry
#define CORRMIN -800 // display min
#define CORRMAX  800 // display max


using namespace std;


//point structure used to render points in open GL
struct Point
{
    float x, y;
    unsigned char r, g, b, a;
};



std::vector< Point > points;

StartSimulation *GalaxyPtr;

int algorithmChoice; //0:brute 1:QuadTree
int ManualNumBody;


//global timing
double resultTotal;
double rounds;

void reshape(int w, int h)
{
    glViewport(0, 0, w, h);
}


void crunch(){

    GalaxyPtr->run(algorithmChoice);

 for( size_t i = 0; i < NUMBODY; ++i )
    {
        points.pop_back();
    }

    for( size_t i = 0; i < NUMBODY; ++i )
    {
        
        Point pt;
       //pt.x = -50 + (rand() % 100);
       //pt.y = -50 + (rand() % 100);
       pt.x =  CORRMIN + GalaxyPtr->GetBody(i).x;
       pt.y =  CORRMIN + GalaxyPtr->GetBody(i).y;

        //printf("\nx:%.2f y:%.2f",pt.x,pt.y);

        pt.r = GalaxyPtr->GetBody(i).r;
        pt.g = GalaxyPtr->GetBody(i).g;
        pt.b = GalaxyPtr->GetBody(i).b;
        pt.a = 255;

        points.push_back(pt);
    }        

}

void setupGL(){

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(CORRMIN,CORRMAX,CORRMIN,CORRMAX, -1, 1);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    // draw
    glColor3ub( 255, 255, 255 );
    glEnableClientState( GL_VERTEX_ARRAY );
    glEnableClientState( GL_COLOR_ARRAY );

    //smooth
 

    glEnable( GL_POINT_SMOOTH );
    glEnable( GL_BLEND );
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glPointSize( 5.0 );

}

void display(void)
{
     struct timespec diff(struct timespec start, struct timespec end);
     struct timespec time1, time2,result;


     clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time1);
    //run simulation
     crunch();
     // setup window
     clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time2);

     result = diff(time1,time2);
     rounds++;

     resultTotal += result.tv_sec * 1E3 +  result.tv_nsec * 1E-6;
     //resultTotal = resultTotal / rounds;

     printf("CPU time:\t%.1f (msec)\n", resultTotal/rounds);

     setupGL();
    
    
    glVertexPointer( 2, GL_FLOAT, sizeof(Point), &points[0].x );
    glColorPointer( 4, GL_UNSIGNED_BYTE, sizeof(Point), &points[0].r );

    glDrawArrays( GL_POINTS, 0, points.size() );

    glDisableClientState( GL_VERTEX_ARRAY );
    glDisableClientState( GL_COLOR_ARRAY );


    //glFlush(); // dont need flush because swap buffer has it intrinsically..used before for single buffer
    glutSwapBuffers();
    glutReshapeFunc(reshape);
}




int main(int argc, char** argv)
{	
    

    
    if (argc > 1)
    {   
    algorithmChoice = atoi( argv[1] );
    }
    else{
    algorithmChoice = 0;

    }
    if(argc >= 2){
        ManualNumBody = atoi( argv[2] );
    }
    else{

        ManualNumBody = 200;
    }

    GalaxyPtr = new StartSimulation(ManualNumBody,GalaxyX,GalaxyY);
    
	
	glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);

    glutInitWindowSize(GalaxyX,GalaxyY);
    glutCreateWindow("Random Points");

    glutDisplayFunc(display);
    glutReshapeFunc(reshape);

    //
    rounds = 0;

    
     // populate points
    for( size_t i = 0; i < NUMBODY; ++i )
    {
        Point pt;
        pt.x = GalaxyPtr->GetBody(i).x;
        pt.y = GalaxyPtr->GetBody(i).y;
        pt.r = GalaxyPtr->GetBody(i).r;
        pt.g = GalaxyPtr->GetBody(i).g;
        pt.b = GalaxyPtr->GetBody(i).b;
        pt.a = 255;
        points.push_back(pt);
    }    
	
    

    glutIdleFunc(display);

	glutMainLoop();


	return 0;
}
/************************************/

struct timespec diff(struct timespec start, struct timespec end)
{
  struct timespec temp;
  if ((end.tv_nsec-start.tv_nsec)<0) {
    temp.tv_sec = end.tv_sec-start.tv_sec-1;
    temp.tv_nsec = 1000000000+end.tv_nsec-start.tv_nsec;
  } else {
    temp.tv_sec = end.tv_sec-start.tv_sec;
    temp.tv_nsec = end.tv_nsec-start.tv_nsec;
  }
  return temp;
}

double fRand(double fMin, double fMax)
{
    double f = (double)random() / RAND_MAX;
    return fMin + f * (fMax - fMin);
}

/************************************/
