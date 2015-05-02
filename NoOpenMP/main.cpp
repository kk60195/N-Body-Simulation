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

#include <GL/glut.h>
#include <sstream>
#include <iomanip>

#include "Body.h"
#include "StartSimulation.h"



#define GRIDSIDES 1000
#define MAXMASS 200 // max mass a body cna get
#define GalaxyX 1000 //0 to boundry
#define GalaxyY 1000 // 0 to boundry
#define CORRMIN -1000 // display min
#define CORRMAX  1000 // display max

// constants
const int   SCREEN_WIDTH    = 400;
const int   SCREEN_HEIGHT   = 300;
const float CAMERA_DISTANCE = 10.0f;
const int   TEXT_WIDTH      = 80;
const int   TEXT_HEIGHT     = 130;


using std::stringstream;
using std::cout;
using std::endl;
using std::ends;
using namespace std;





//point structure used to render points in open GL
struct Point
{
    float x, y;
    unsigned char r, g, b, a;
};


//global
std::vector< Point > points;
StartSimulation *GalaxyPtr;
int algorithmChoice; //0:brute 1:QuadTree
int ManualNumBody;
void *font = GLUT_BITMAP_TIMES_ROMAN_24;

//global timing
double resultTotal;
double rounds;


void drawString(const char *str, int x, int y, float color[4], void *font)
{
    glPushAttrib(GL_LIGHTING_BIT | GL_CURRENT_BIT); // lighting and color mask
    glDisable(GL_LIGHTING);     // need to disable lighting for proper text color
    glDisable(GL_TEXTURE_2D);

    glColor4fv(color);          // set text color
    glRasterPos2i(x, y);        // place text position

    // loop all characters in the string
    while(*str)
    {
        glutBitmapCharacter(font, *str);
        ++str;
    }

    glEnable(GL_TEXTURE_2D);
    glEnable(GL_LIGHTING);
    glPopAttrib();
}

void showInfo(double timing)
{
    // backup current model-view matrix
    glPushMatrix();                     // save current modelview matrix
    glLoadIdentity();                   // reset modelview matrix

    // set to 2D orthogonal projection
    glMatrixMode(GL_PROJECTION);        // switch to projection matrix
    glPushMatrix();                     // save current projection matrix
    glLoadIdentity();                   // reset projection matrix
    gluOrtho2D(0, GalaxyX, 0, GalaxyY); // set to orthogonal projection

    float color[4] = {1, 1, 1, 1};

    stringstream ss;
    ss << std::fixed << std::setprecision(3);

    ss << "Timing " << timing <<  "Msec" << " \n #Obj: " << ManualNumBody << "\n Iter: " << rounds <<ends;
    drawString(ss.str().c_str(), 1, 950, color, font);
    ss.str("");


    // unset floating format
    ss << std::resetiosflags(std::ios_base::fixed | std::ios_base::floatfield);

    // restore projection matrix
    glPopMatrix();                   // restore to previous projection matrix

    // restore modelview matrix
    glMatrixMode(GL_MODELVIEW);      // switch to modelview matrix
    glPopMatrix();                   // restore to previous modelview matrix
}


void reshape(int w, int h)
{
    glViewport(0, 0, w, h);
}


void crunch(){

     struct timespec diff(struct timespec start, struct timespec end);
     struct timespec time1, time2,result;
     clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time1);
    //run simulation

    GalaxyPtr->run(algorithmChoice);

     clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time2);
     result = diff(time1,time2);
     rounds++;
     resultTotal += result.tv_sec * 1E3 +  result.tv_nsec * 1E-6;
     //resultTotal = resultTotal / rounds;
     printf("CPU time:\t%.1f (msec)\n", resultTotal/rounds);
      //text
     




 for( size_t i = 0; i < ManualNumBody; ++i )
    {
        points.pop_back();
    }

    for( size_t i = 0; i < ManualNumBody; ++i )
    {
        
        Point pt;
     
       pt.x =  CORRMIN + GalaxyPtr->GetBody(i).x;
       pt.y =  CORRMIN + GalaxyPtr->GetBody(i).y;

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
    
    glPointSize( 8.0 );

}

void remakeGalaxy(int BodyCount){

    //if(GalaxyPtr){
    //    delete GalaxyPtr;
    //}
    int i;

        for( i = 0; i < ManualNumBody ; i++){
             free(GalaxyPtr);

        }

    ManualNumBody += 100;
    rounds = 0;
    

    GalaxyPtr = new StartSimulation(ManualNumBody,GalaxyX,GalaxyY);

}

void display(void)
{

    //if(rounds == 400){
        //remakeGalaxy(100);
    //}

    //run simulation
     crunch();

     //refactor
     setupGL();
    
    //draw
    glVertexPointer( 2, GL_FLOAT, sizeof(Point), &points[0].x );
    glColorPointer( 4, GL_UNSIGNED_BYTE, sizeof(Point), &points[0].r );

    glDrawArrays( GL_POINTS, 0, points.size() );

    glDisableClientState( GL_VERTEX_ARRAY );
    glDisableClientState( GL_COLOR_ARRAY );

     
    //display text
    showInfo(resultTotal/rounds);
   
    glFlush(); // dont need flush because swap buffer has it intrinsically..used before for single buffer
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
    //rounds = 0;



    
    
     // populate points
    for( size_t i = 0; i < ManualNumBody; ++i )
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
    
    

    int i = 0;

    for(i = 0; i < 10; i++){
        display();

    }
    //glutIdleFunc(display);

    //glutMainLoop();


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
/************************************/