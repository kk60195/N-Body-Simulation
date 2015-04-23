//g++ -O2 -o main main.cpp
#include <iostream>
#include <string>
#include <time.h> 
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */      
#include <vector>
#include <cstdlib>

#include "Body.h"
#include "StartSimulation.h"
#include <GL/glut.h>

#define GRIDSIDES 1000
#define NUMBODY 5
#define MAXMASS 20
#define GalaxyX 600
#define GalaxyY 500

using namespace std;



struct Point
{
    float x, y;
    unsigned char r, g, b, a;
};

std::vector< Point > points;

StartSimulation Galaxy(NUMBODY);

void reshape(int w, int h)
{
    glViewport(0, 0, w, h);
}


void crunch(){

 for( size_t i = 0; i < NUMBODY; ++i )
    {
        points.pop_back();
    }

    for( size_t i = 0; i < NUMBODY; ++i )
    {
        
        Point pt;
       pt.x = -50 + (rand() % 100);
       pt.y = -50 + (rand() % 100);
        pt.x = Galaxy.GetBody(i).x;
        pt.y = Galaxy.GetBody(i).y;

        printf("\nx:%.2f y:%.2f",pt.x,pt.y);
        pt.r = 100;//rand() % 255;
        pt.g = 100;//rand() % 255;
        pt.b = 100;//rand() % 255;
        pt.a = 255;
        points.push_back(pt);
    }        

}

void display(void)
{


    int count;

    //Galaxy = new StartSimulation(5);

   // StartSimulation s1(5);
    
     crunch();

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-500, 500, -500, 500, -1, 1);

    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    // draw
    glColor3ub( 255, 255, 255 );
    glEnableClientState( GL_VERTEX_ARRAY );
    glEnableClientState( GL_COLOR_ARRAY );
    glVertexPointer( 2, GL_FLOAT, sizeof(Point), &points[0].x );
    glColorPointer( 4, GL_UNSIGNED_BYTE, sizeof(Point), &points[0].r );
    glPointSize( 3.0 );
    glDrawArrays( GL_POINTS, 0, points.size() );
    glDisableClientState( GL_VERTEX_ARRAY );
    glDisableClientState( GL_COLOR_ARRAY );

    glFlush();
    glutSwapBuffers();


    glutReshapeFunc(reshape);
}




int main(int argc, char** argv)
{	
    /*

    int count;
    if (argc > 1)
    {   
    count = atoi( argv[1] );

    StartSimulation s1(count);
    }
    else{
    StartSimulation s1(5);
    }
    */
	
	glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);

    glutInitWindowSize(GalaxyX,GalaxyY);
    glutCreateWindow("Random Points");

    glutDisplayFunc(display);
    glutReshapeFunc(reshape);

     // populate points
    for( size_t i = 0; i < NUMBODY; ++i )
    {
        Point pt;
        pt.x = Galaxy.GetBody(i).x;
        pt.y = Galaxy.GetBody(i).y;
        pt.r = 100;//rand() % 255;
        pt.g = 10;//rand() % 255;
        pt.b = 10;rand() % 255;
        pt.a = 255;
        points.push_back(pt);
    }    
	
    //glutMainLoop();

    glutIdleFunc(display);

	glutMainLoop();
	return 0;
}