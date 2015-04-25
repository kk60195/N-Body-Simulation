//g++ -O2 -o main main.cpp
#include <iostream>
#include <string>
#include <time.h> 
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */      
#include <vector>
#include <cstdlib>
#include <math.h>

#include "Body.h"
#include "StartSimulation.h"
#include <GL/glut.h>


#define GRIDSIDES 1000
#define NUMBODY 200  //number of stars generated
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

StartSimulation Galaxy(NUMBODY,GalaxyX,GalaxyY);

int algorithmChoice; //0:brute 1:QuadTree

void reshape(int w, int h)
{
    glViewport(0, 0, w, h);
}


void crunch(){

    Galaxy.run(algorithmChoice);

 for( size_t i = 0; i < NUMBODY; ++i )
    {
        points.pop_back();
    }

    for( size_t i = 0; i < NUMBODY; ++i )
    {
        
        Point pt;
       //pt.x = -50 + (rand() % 100);
       //pt.y = -50 + (rand() % 100);
       pt.x =  CORRMIN + Galaxy.GetBody(i).x;
       pt.y =  CORRMIN + Galaxy.GetBody(i).y;

        //printf("\nx:%.2f y:%.2f",pt.x,pt.y);

        pt.r = Galaxy.GetBody(i).r;
        pt.g = Galaxy.GetBody(i).g;
        pt.b = Galaxy.GetBody(i).b;
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
    
    glPointSize( 4.0 );

}

void display(void)
{


    //run simulation
     crunch();
     // setup window
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
        pt.r = Galaxy.GetBody(i).r;
        pt.g = Galaxy.GetBody(i).g;
        pt.b = Galaxy.GetBody(i).b;
        pt.a = 255;
        points.push_back(pt);
    }    
	
    

    glutIdleFunc(display);

	glutMainLoop();


	return 0;
}