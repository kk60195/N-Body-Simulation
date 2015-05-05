//gcc -O1 -fopenmp -o main main.c -lrt -lm


#include <stdio.h> //fopen/fclose/printf/gets/puts
#include <stdlib.h> //variable types defined size_t/malloc/atoi/rand/abs
#include <time.h> //struct timspec/clock_gettime/CLOCK_PROCESS_CPUTIME_TIM
#include <math.h>
#include <pthread.h> // pthreads
#include <omp.h> // openmp

#include "cuPrintf.cu" // cuda print
#include "cuPrintf.cuh" //cuda print


#include <GL/glut.h> //openGL
//#include <sstream>
//#include <iomanip>


#define GIG 1000000000
#define CPG 3.168           // Cycles per GHz -- Adjust to your computer

#define YMAX 10000
#define XMAX 10000
#define CORRMIN -1E4 // display min
#define CORRMAX  1E4 // display max
#define MASSMAX 500
#define TIMESTEP 1
#define POINTSIZE 4.0

#define BODYPROPCOUNT 7 //x,y,m,vx,vy,fx,fy
#define GRAVITYCONST 6E-11
#define RADIUSINVISIBLE 100 //two planets dont see each other when they are within this distance

const int BLOCKSIZE = 1024; 

//openGL Constants
const int   SCREEN_WIDTH    = 400;
const int   SCREEN_HEIGHT   = 300;
const float CAMERA_DISTANCE = 10.0f;
const int   TEXT_WIDTH      = 80;
const int   TEXT_HEIGHT     = 130;

typedef double data_t;



//point structure used to render points in open GL
typedef struct Point
{
    float x, y;
    unsigned char r, g, b, a;
} Point_rec, *Point_ptr;

//holds points
typedef struct Points
{
Point_ptr data;
data_t len; // Total size of the vector
data_t current; //Number of vectors in it at present
} Points_rec, *Points_ptr;


//Text GL
void *font = GLUT_BITMAP_TIMES_ROMAN_24;

//strudture to hold galaxies
typedef struct {
	long int len;
	data_t *Bodies;
} Body_rec, *Body_ptr;

/* NUMBER of bytes in a vector */
#define VBYTES 16

/* Number o elements in a vector 
#define VSIZE VBYTES/sizeof(data_t)
typedef data_t Body_t _attribute_((vector_size(VBYTES)));
typedef union { 
	Body_t v;
	data_t d[VSIZE];

}pack_t;
*/


//Global Variables
Body_ptr Galaxy;
Points_ptr points;
double resultTotal;
int rounds;
int algorithmChoice;
int ManualNumBody;
/**********************************************************************/

//GPU

__global__ 
void ComputeForce(data_t *Bodies, long int len) 
{
  //a[threadIdx.x] += b[threadIdx.x];
  int myid = blockIdx.x * blockDim.x + threadIdx.x;
  int j;
  double x_dist,y_dist;
  double r_Squared;
  double dist;
  double Force;
  //cuPrintf("hello%d\n", myid);


  Bodies[myid + 5 *len] = 0;
  Bodies[myid + 6 *len] = 0;

  for(j = 0 ; j< len; j++){

        if(myid!=j){
          
            x_dist = Bodies[myid] - Bodies[j];
            y_dist = Bodies[myid + len] - Bodies[j + len];
            r_Squared = (x_dist*x_dist)  + (y_dist*y_dist);
            dist = sqrt(r_Squared);

            if(dist > RADIUSINVISIBLE){

              Force = (Bodies[myid + 2 * len] * Bodies[j + 2 * len] )/ (dist *dist * len /2);
              Bodies[myid + 5 * len] -= Force * x_dist ;/// dist;
              Bodies[myid + 6 * len] -= Force * y_dist ;/// dist;

            }
        }
  }


 //__syncthreads();

  for(j = 0 ; j< gridDim.x; j++){
        Bodies[myid + 3*len] += Bodies[myid + 5 * len] * TIMESTEP/ Bodies[myid + 2 * len];
        Bodies[myid + 4*len] += Bodies[myid + 6 * len] * TIMESTEP/ Bodies[myid + 2 * len];

         Bodies[myid] += Bodies[myid + 3 * len] * TIMESTEP;
         Bodies[myid + len] += Bodies[myid + 4 * len] * TIMESTEP;
     
  } 
}




/******************************************************************/
main(int argc, char *argv[]){

//iterative variable
int i;

//variable declare


//function declares
//struct timespec diff(struct timespec start, struct timespec end);
//struct timespec time1,time2,Diff;
Body_ptr new_galaxy(long int len);
Points_ptr new_points(long int len);
void display();
void reshape(int w, int h);


//calculation functions
void BruteForce(Body_ptr G);



//parse ArgC
if (argc > 1) 
    algorithmChoice = atoi( argv[1] );
    else algorithmChoice = 0;

if(argc >= 2)
    ManualNumBody = atoi( argv[2] );
    else ManualNumBody = 200;
    

//create galaxy
Galaxy = new_galaxy(ManualNumBody);

//debug printing
// for(i = 0 ; i < BODYPROPCOUNT; i++){
// 	for(j = 0 ; j < ManualNumBody; j++){
// 		printf("%.1f\t",Galaxy->Bodies[i*ManualNumBody + j]);
// 	}
// 	printf("\n");
// }


if(false){ // non cuda runs
if( algorithmChoice == 0){

//brute force
	//clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time1);
    BruteForce(Galaxy);
    //clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time2);
    //Diff = diff(time1,time2);
    //printf("\nTime: %ld\n", (long int)((double)(GIG * Diff.tv_sec + Diff.tv_nsec)));
}

//bruteforce gpu
if(algorithmChoice == 1){

    data_t *CBody;
    const int CSize = Galaxy->len * BODYPROPCOUNT * sizeof(Body_rec);

    cudaMalloc( (void**)&CBody, CSize);

    cudaMemcpy(CBody, Galaxy->Bodies,CSize, cudaMemcpyHostToDevice);

    dim3 dimBlock(1,1);
    dim3 dimGrid(ManualNumBody,1);

    ComputeForce<<<dimGrid,dimBlock>>>(CBody,Galaxy->len);

    cudaMemcpy(Galaxy->Bodies,CBody,CSize, cudaMemcpyDeviceToHost);


    cudaFree(CBody);
}

}

//Create Points to show

points = new_points(ManualNumBody);

//open GL
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);

    glutInitWindowSize(XMAX,YMAX);
    glutCreateWindow("Random Points");

    glutDisplayFunc(display);
    glutReshapeFunc(reshape);

//initate a set of points

    for( i = 0; i < ManualNumBody; i++ )
    {
        
        points->data[i].x = Galaxy->Bodies[i];
        points->data[i].y = Galaxy->Bodies[i + ManualNumBody];
        points->data[i].r = rand()%255;
        points->data[i].g = rand()%255;
        points->data[i].b = rand()%255;
        points->data[i].a = 255;
        
    }        

    glutIdleFunc(display);

    glutMainLoop();


}

/***********************************/


// create space
Body_ptr new_galaxy(long int len){
	//function declare
	int init_bodies_rand(Body_ptr v, long int len);
 	int success;

	//making the head object
	Body_ptr result = (Body_ptr)malloc(sizeof(Body_rec));
	//catch
	if(!result)return NULL;
	result->len = len;

	//Make the Galaxies x,y,vx,vy,fx,fy,m
	if(len > 0){
		data_t *Bodies = (data_t *) calloc(len*BODYPROPCOUNT, sizeof(data_t));
		if(!Bodies){
			free((void*) result);
			printf("\n COULDN'T ALLOCATE STORAGE \n", result->len);
			return NULL;
		}
		//assign object into head object
		result->Bodies = Bodies;

		//populate the bodies
		success = init_bodies_rand(result, result->len);

	}
	else result->Bodies = NULL;



	return result;
}

/************************************/
//calculate difference in timsepcs
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
//random function with seed
double fRand(double fMin, double fMax)
{
    double f = (double)random() / RAND_MAX;
    return fMin + f * (fMax - fMin);
}

//fill bodies with x,y and m
int init_bodies_rand(Body_ptr G, long int len)
{
  long int i;
  double fRand(double fMin, double fMax);

  if (len > 0) {
    //G->len = len;
    for (i = 0; i < len; i++){
      G->Bodies[i] = (data_t)(fRand((double)(0),(double)(XMAX))); // x
  	  G->Bodies[1*len + i] = (data_t)(fRand((double)(0),(double)(YMAX))); //y
  	  G->Bodies[2*len + i] = (data_t)(fRand((double)(0),(double)(MASSMAX))); //m

  	}
    return 1;
  }
  else return 0;
}
/*****************************************************/
//points declare for OPENGL
Points_ptr new_points(long int len){
	

	//making the head object
	Points_ptr result = (Points_ptr)malloc(sizeof(Points_rec));
	//catch
	if(!result)return NULL;
	result->len = len;

	//Make the Galaxies x,y,vx,vy,fx,fy,m
	if(len > 0){
		Point_ptr points = (Point_ptr) calloc(len, sizeof(Point_rec));
		if(!points){
			free((void*) result);
			printf("\n COULDN'T ALLOCATE STORAGE \n", result->len);
			return NULL;
		}
		//assign object into head object
		result->data = points;

		result->current = 0;


	}
	else result->data = NULL;



	return result;


}
void crunch(long int len){
	//calculation functions

	void BruteForce(Body_ptr G);


     //struct timespec diff(struct timespec start, struct timespec end);
     struct timespec time1, time2,result;
     clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time1);
    //run simulation
     if(algorithmChoice == 0){
	         BruteForce(Galaxy);
     }
     //run GPU
     if(algorithmChoice == 1){

         data_t *CBody;
         const int CSize = Galaxy->len * BODYPROPCOUNT * sizeof(data_t);

         cudaMalloc( (void**)&CBody, CSize);

          cudaMemcpy(CBody, Galaxy->Bodies,CSize, cudaMemcpyHostToDevice);

          dim3 dimBlock(BLOCKSIZE,1);
          dim3 dimGrid(ManualNumBody/BLOCKSIZE,1);

          ComputeForce<<<dimGrid,dimBlock>>>(CBody,Galaxy->len);

          cudaMemcpy(Galaxy->Bodies,CBody,CSize, cudaMemcpyDeviceToHost);
          cudaFree(CBody);

          cudaMalloc( (void**)&CBody, CSize);

          cudaMemcpy(CBody, Galaxy->Bodies,CSize, cudaMemcpyHostToDevice);

          //dim3 dimBlock(ManualNumBody%1024,1);
          //dim3 dimGrid(1,1);

          ComputeForce<<<1,ManualNumBody%BLOCKSIZE>>>(CBody,Galaxy->len);

          cudaMemcpy(Galaxy->Bodies,CBody,CSize, cudaMemcpyDeviceToHost);
          cudaFree(CBody);


     }


     clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time2);
     result = diff(time1,time2);
     
     resultTotal = result.tv_sec * 1E3 +  result.tv_nsec * 1E-6;
     resultTotal = resultTotal;
     printf("CPU time:\t%.1f (msec)\n", resultTotal);
      //text
    
    //reset display points 
  	int i;
    for(  i = 0; i < len; i++ )
    {
        
        points->data[i].x = CORRMAX/2-XMAX + Galaxy->Bodies[i];
        points->data[i].y = CORRMAX/2-YMAX + Galaxy->Bodies[i + ManualNumBody];
        points->data[i].r = abs( (unsigned char)(Galaxy->Bodies[i + 2 * ManualNumBody]) % 255);
        points->data[i].g =  abs( (unsigned char)(Galaxy->Bodies[i + 2 * ManualNumBody]) % 255);
        points->data[i].b = 255;
        points->data[i].a = 255;

    

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
    
    glPointSize( POINTSIZE );

}

void reshape(int w, int h)
{
    glViewport(0, 0, w, h);
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
    gluOrtho2D(0, XMAX, 0, YMAX); // set to orthogonal projection

    float color[4] = {1, 1, 1, 1};

    //stringstream ss;
    //ss << std::fixed << std::setprecision(3);

    //ss << "Timing " << timing <<  "Msec" << " \n #Obj: " << ManualNumBody << "\n Iter: " << rounds <<ends;
    //drawString(ss.str().c_str(), 1, 950, color, font);
    //ss.str("");


    // unset floating format
    //ss << std::resetiosflags(std::ios_base::fixed | std::ios_base::floatfield);

    // restore projection matrix
    glPopMatrix();                   // restore to previous projection matrix

    // restore modelview matrix
    glMatrixMode(GL_MODELVIEW);      // switch to modelview matrix
    glPopMatrix();                   // restore to previous modelview matrix
}

void display()
{


    //run simulation
     crunch(points->len);

     //refactor
     setupGL();
    
    //draw
    glVertexPointer( 2, GL_FLOAT, sizeof(Point_ptr), &(points->data[0].x) );
    glColorPointer( 4, GL_UNSIGNED_BYTE, sizeof(Point_ptr), &(points->data[0].r) );

    glDrawArrays( GL_POINTS, 0, points->len );

    glDisableClientState( GL_VERTEX_ARRAY );
    glDisableClientState( GL_COLOR_ARRAY );

     
    //display text
    //showInfo(resultTotal/rounds);
   
    glFlush(); // dont need flush because swap buffer has it intrinsically..used before for single buffer
    glutSwapBuffers();
    glutReshapeFunc(reshape);
}


/******************************************/
void BruteForce(Body_ptr G){

//iterators
int i,j,len;
len = G->len;

//reference placement
long int x,y,m,vx,vy,fx,fy;
x = 0;
y = len;
m = len * 2;
vx = len * 3;
vy = len * 4;
fx = len * 5;
fy = len * 6;

//calculation
double m1,m2,dy,dx,dt,dtsq,force;

data_t *Bodies = G->Bodies;

//compute forces
for(i = 0 ; i < len; i++){

	Bodies[i + fx] = 0; //reset fx
	Bodies[i + fy] = 0; //reset fy

	for( j = 0; j < len; j++){
		if(i!=j){

			m1 = Bodies[i + m];
			m2 = Bodies[j + m];
			dx = Bodies[i + x] - Bodies[j + x];
			dy = Bodies[i + y] - Bodies[j + y];
			dtsq = dx * dx + dy * dy;
			dt = sqrt(dtsq);
			force = (m1 * m2  * GRAVITYCONST * 6E11) / (dtsq);

			//Set force
      if(dt > 100){
		    Bodies[i + fx] += (dx/dt) * force; //set fx
		    Bodies[i + fy] += (dy/dt) * force; //set fy
      }
		}
	}

}

//apply forces
for( i = 0 ; i < len ; i++){


	Bodies[i + vx] += Bodies[i + fx] * TIMESTEP / Bodies[i + m]; //set vx += fx /m
	Bodies[i + vy] += Bodies[i + fy] * TIMESTEP / Bodies[i + m]; //set vy += fy /m

	Bodies[i + x] -= Bodies[i + vx] * TIMESTEP; //new x +=vx
	Bodies[i + y] -= Bodies[i + vy] * TIMESTEP; //new y +=vy
}


}