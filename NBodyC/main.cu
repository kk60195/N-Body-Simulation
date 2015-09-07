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
#define POINTSIZE 2.0

#define BODYPROPCOUNT 7 //x,y,m,vx,vy,fx,fy
#define GRAVITYCONST 6E-11
#define RADIUSINVISIBLE 100 //two planets dont see each other when they are within this distance


#define TREELEVEL 6

#define TREEPROPCOUNT 11 //xmin, xmax, ymin, ymax, m, mx, my, child1, child2, child3, child4
#define THETA 0.5

const int BLOCKSIZE = 1024; 

//openGL Constants
const int   SCREEN_WIDTH    = 400;
const int   SCREEN_HEIGHT   = 300;
const float CAMERA_DISTANCE = 10.0f;
const int   TEXT_WIDTH      = 80;
const int   TEXT_HEIGHT     = 130;

typedef float data_t;



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

//strudture to hold galaxies, include all the bodies
typedef struct {
	long int len;
	data_t *Bodies;
} Body_rec, *Body_ptr;

//structure to hold the tree, include all the tree nodes
typedef struct{
  long int numNode;
  data_t *Nodes;
} Node_rec, *Node_ptr;

/* NUMBER of bytes in a vector */
#define VBYTES 16



//Global Variables
Body_ptr Galaxy;
Points_ptr points;
float resultTotal;
int rounds;
int algorithmChoice;
int ManualNumBody;
Node_ptr MyTree;



/**********************************************************************/
//cuda bruteforce
__global__ 
void ComputeForce(data_t *Bodies, long int len) 
{

  
  //a[threadIdx.x] += b[threadIdx.x];
  int myid = blockIdx.x * blockDim.x + threadIdx.x;
  int j;
  float x_dist,y_dist;
  float r_Squared;
  float dist;
  float Force;
  //cuPrintf("hello%d\n", myid);
  if(myid < len){

    Bodies[myid + 5 *len] = 0;
    Bodies[myid + 6 *len] = 0;
    
    //for each body, calculate it force against all the other bodies
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

    for(j = 0 ; j< gridDim.x; j++){
          Bodies[myid + 3*len] += Bodies[myid + 5 * len] * TIMESTEP/ Bodies[myid + 2 * len];
          Bodies[myid + 4*len] += Bodies[myid + 6 * len] * TIMESTEP/ Bodies[myid + 2 * len];

          Bodies[myid] += Bodies[myid + 3 * len] * TIMESTEP;
          Bodies[myid + len] += Bodies[myid + 4 * len] * TIMESTEP;
       
    } 
  }
}



/***********************************/
//cuda code for barnes-hut
__global__ 
void ComputeBarnes(data_t *Bodies ,long int len, data_t * Nodes , long int num, int num0) 
{


  int myid = blockIdx.x * blockDim.x + threadIdx.x;
  int i, j,k;
  float x_dist,y_dist,dtsq,dist,m1,m2;
  float force;

//for each body, calculate it's force against all the lowest level tree nodes
  if(myid < len){

    Bodies[myid + 5 *len] = 0;
    Bodies[myid + 6 *len] = 0;
    
    for (j = num0; j < num; j++ ){
      x_dist = Bodies[myid] - Nodes[j + num*5];
      y_dist = Bodies[myid + len] - Nodes[j + num*6];
      dtsq = x_dist*x_dist + y_dist*y_dist;
      dist = sqrt(dtsq);
      m1 = Bodies[myid + len*2];
      m2 = Nodes[j + num*4];
      if(dist > 100){
        force = (m1 * m2  * GRAVITYCONST * 6E9) / (dtsq);
         
        Bodies[myid + len*5] +=  (-x_dist/dist) * force ;
        Bodies[myid + len*6] +=  (-y_dist/dist) * force ;
      }
    }

    Bodies[myid + 3*len] += Bodies[myid + 5 * len] * TIMESTEP/ Bodies[myid + 2 * len];
    Bodies[myid + 4*len] += Bodies[myid + 6 * len] * TIMESTEP/ Bodies[myid + 2 * len];

    Bodies[myid] += Bodies[myid + 3 * len] * TIMESTEP;
    Bodies[myid + len] += Bodies[myid + 4 * len] * TIMESTEP;
  }

}


/******************************************************************/
main(int argc, char *argv[]){

  //iterative variable
  int i, j;


  Body_ptr new_galaxy(long int len);
  Points_ptr new_points(long int len);
  void display();
  void reshape(int w, int h);
  Node_ptr new_tree();


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

  MyTree = new_tree();





  //needed
  points = new_points(ManualNumBody);

  //open GL
  glutInit(&argc, argv);
  glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);

  glutInitWindowSize(XMAX,YMAX);
  glutCreateWindow("Random Points");

  glutDisplayFunc(display);
  glutReshapeFunc(reshape);

//initate a set of points

  for( i = 0; i < ManualNumBody; ++i )
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
//create tree 
Node_ptr new_tree(){
  int init_tree(Node_ptr T, int curIndex, int curLevel);//initialize xmin xmax ymin ymax
  long int num = (pow(4,TREELEVEL) - 1)/3;
  int success;

  Node_ptr nodept = (Node_ptr)malloc(sizeof(Node_rec));
  //catch
  if(!nodept)return NULL;
   nodept->numNode = num;

  //make the tree
  if(nodept->numNode > 0){
    data_t *Nodes = (data_t *)calloc(nodept->numNode*TREEPROPCOUNT, sizeof(data_t));
    if(!Nodes){
      free((void*) nodept);
      printf("\n COULDN'T ALLOCATE STORAGE \n", nodept->numNode);
      return NULL;
    }
    //
    nodept->Nodes = Nodes;
    success = init_tree(nodept, 0, 1);
  }else{
    nodept->Nodes = NULL;
  }

  return nodept;
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
float fRand(float fMin, float fMax)
{
    float f = (float)random() / RAND_MAX;
    return fMin + f * (fMax - fMin);
}


/********/
//fill bodies with x,y and m
int init_bodies_rand(Body_ptr G, long int len)
{
  long int i;
  float fRand(float fMin, float fMax);

  if (len > 0) {
    //G->len = len;
    for (i = 0; i < len; i++){
      G->Bodies[i] = (data_t)(fRand((float)(0),(float)(XMAX))); // x
  	  G->Bodies[1*len + i] = (data_t)(fRand((float)(0),(float)(YMAX))); //y
  	  G->Bodies[2*len + i] = (data_t)(fRand((float)(0),(float)(MASSMAX))); //m

  	}
    return 1;
  }
  else return 0;
}




/*************************************/
//reset the tree
void reset_tree(){
  int i,j;
  int num = MyTree-> numNode;

  for(i = 4 ; i < 7; i++){                //
    for(j = 0; j < num; j++){
      MyTree->Nodes[num*i + j] = 0;
    }
  }
}



/************************************/
//init treenodes
int init_tree(Node_ptr T, int curIndex, int curLevel)
{
  long int i,j;
  long int temp1,temp2,temp3,temp4;
  long int num = T->numNode;


  if (num > 0){
//for root node
    if(curIndex == 0){

      T->Nodes[curIndex] = 0;
      T->Nodes[curIndex + 1*num] = XMAX;
      T->Nodes[curIndex + 2*num] = 0;
      T->Nodes[curIndex + 3*num] = YMAX;

      T->Nodes[curIndex + 7*num] = curIndex*4+1;
      T->Nodes[curIndex + 8*num] = curIndex*4+2;
      T->Nodes[curIndex + 9*num] = curIndex*4+3;
      T->Nodes[curIndex + 10*num] = curIndex*4+4; 
      init_tree(T, curIndex*4+1, curLevel+1);
      init_tree(T, curIndex*4+2, curLevel+1);
      init_tree(T, curIndex*4+3, curLevel+1);
      init_tree(T, curIndex*4+4, curLevel+1);

    }else{//not rootnode
      //get mid values of parent's region
      temp1 = (curIndex-1)/4;//parent's index
      temp2 = curIndex-1 - 4*temp1;// figure out which child is the current node to it's parent
      temp3 = (T->Nodes[temp1] + T->Nodes[temp1 + 1*num])/2;
      temp4 = (T->Nodes[temp1 + 2*num] + T->Nodes[temp1 + 3*num])/2;
      if(temp2==0){// bottom left
        T->Nodes[curIndex] = T->Nodes[temp1];
        T->Nodes[curIndex + 1*num] = temp3;
        T->Nodes[curIndex + 2*num] = T->Nodes[temp1 + 2*num];
        T->Nodes[curIndex + 3*num] = temp4;
      }else if(temp2==1){//bottom right
        T->Nodes[curIndex] = temp3;
        T->Nodes[curIndex + 1*num] = T->Nodes[temp1 + 1*num];
        T->Nodes[curIndex + 2*num] = T->Nodes[temp1 + 2*num];
        T->Nodes[curIndex + 3*num] = temp4;
      }else if(temp2==2){//top left
        T->Nodes[curIndex] = T->Nodes[temp1];
        T->Nodes[curIndex + 1*num] = temp3;
        T->Nodes[curIndex + 2*num] = temp4;
        T->Nodes[curIndex + 3*num] = T->Nodes[temp1 + 3*num];
      }else if(temp2==3){//top right
        T->Nodes[curIndex] = temp3;
        T->Nodes[curIndex + 1*num] = T->Nodes[temp1 + 1*num];
        T->Nodes[curIndex + 2*num] = temp4;
        T->Nodes[curIndex + 3*num] = T->Nodes[temp1 + 3*num];
      }else return 0;

      //for nodes on higher levels, specify their children
      if(curLevel<TREELEVEL){
        T->Nodes[curIndex + 7*num] = curIndex*4+1;
        T->Nodes[curIndex + 8*num] = curIndex*4+2;
        T->Nodes[curIndex + 9*num] = curIndex*4+3;
        T->Nodes[curIndex + 10*num] = curIndex*4+4;
        init_tree(T, curIndex*4+1, curLevel+1);
        init_tree(T, curIndex*4+2, curLevel+1);
        init_tree(T, curIndex*4+3, curLevel+1);
        init_tree(T, curIndex*4+4, curLevel+1);
      }else{//if on the last level
        T->Nodes[curIndex + 7*num] = -1;
        T->Nodes[curIndex + 8*num] = -1;
        T->Nodes[curIndex + 9*num] = -1;
        T->Nodes[curIndex + 10*num] = -1;
      }

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


/***************************************/
//perform one cycle calculations
void crunch(long int len){
	//calculation functions

	void BruteForce(Body_ptr G);
  void quadTree();
  void insertBody(int bodyIndex, int curIndex, int curLevel);

  //struct timespec diff(struct timespec start, struct timespec end);
  struct timespec time1, time2,result;
  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time1);

//run simulation
//cpu brute-force
  if(algorithmChoice == 0){
    BruteForce(Galaxy);
  }

//cuda brute-force
  if(algorithmChoice == 1){

    data_t *CBody;
    const int CSize = Galaxy->len * BODYPROPCOUNT * sizeof(data_t);

    cudaMalloc( (void**)&CBody, CSize);

    cudaMemcpy(CBody, Galaxy->Bodies,CSize, cudaMemcpyHostToDevice);

    dim3 dimBlock(BLOCKSIZE,1);
    dim3 dimGrid(ManualNumBody/BLOCKSIZE+1,1);

    ComputeForce<<<dimGrid,dimBlock>>>(CBody,Galaxy->len);

    cudaMemcpy(Galaxy->Bodies,CBody,CSize, cudaMemcpyDeviceToHost);
    cudaFree(CBody);
  }
//cpu barnes-hut
  if(algorithmChoice == 2){
    quadTree();
  }

//cuda barnes-hut
  if(algorithmChoice == 3){
    void insertBody(int bodyIndex, int curIndex, int curLevel);
    void reset_tree();
    reset_tree();

    int i,j,len,num,num0;
    len = Galaxy->len;
    num = MyTree->numNode;

    long int bx,by,bm,bvx,bvy,bfx,bfy;

    
    bx = 0;
    by = len;
    bm = len * 2;
    bvx = len * 3;
    bvy = len * 4;
    bfx = len * 5;
    bfy = len * 6;
    num0 = (pow(4, TREELEVEL-1) - 1)/3;


    for(i = 0; i < len; i++){
      insertBody(i,0,1);
    }

    data_t *CBody;
    data_t *CNode;

    const int CBodySize = Galaxy->len * BODYPROPCOUNT * sizeof(data_t);
    const int CNodeSize = MyTree->numNode * TREEPROPCOUNT * sizeof(data_t);

    cudaMalloc( (void**)&CBody, CBodySize);
    cudaMalloc((void**)&CNode, CNodeSize);

    cudaMemcpy(CBody, Galaxy->Bodies,CBodySize, cudaMemcpyHostToDevice);
    cudaMemcpy(CNode, MyTree->Nodes,CNodeSize, cudaMemcpyHostToDevice); 

    dim3 dimBlock(BLOCKSIZE,1);
    dim3 dimGrid(ManualNumBody/BLOCKSIZE+1,1);

    ComputeBarnes<<<dimGrid,dimBlock>>>(CBody,Galaxy->len,CNode,MyTree->numNode,num0);

    cudaMemcpy(Galaxy->Bodies,CBody,CBodySize, cudaMemcpyDeviceToHost);
    cudaMemcpy(MyTree->Nodes,CNode,CNodeSize, cudaMemcpyDeviceToHost);
    cudaFree(CBody);
    cudaFree(CNode);
  }

  clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time2);
  result = diff(time1,time2);
   
  resultTotal = result.tv_sec * 1E3 +  result.tv_nsec * 1E-6;
  resultTotal = resultTotal;
  printf("CPU time:\t%.1f (msec)\n", resultTotal);
    //text
  
  //reset display points 
	int i;
  for(  i = 0; i < len; ++i )
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

void showInfo(float timing)
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
    glVertexPointer( 2, GL_FLOAT, sizeof(Point_rec), &(points->data[0].x) );
    glColorPointer( 4, GL_UNSIGNED_BYTE, sizeof(Point_rec), &(points->data[0].r) );

    glDrawArrays( GL_POINTS, 0, points->len );

    glDisableClientState( GL_VERTEX_ARRAY );
    glDisableClientState( GL_COLOR_ARRAY );
     
    //display text   
    glFlush(); // dont need flush because swap buffer has it intrinsically..used before for single buffer
    glutSwapBuffers();
    glutReshapeFunc(reshape);
}


/******************************************/
//the calculate force func for cpu bruteforce method
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
  float m1,m2,dy,dx,dt,dtsq,force;

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

/************************************/
//insert bodies into tree
void insertBody(int bodyIndex, int curIndex, int curLevel){
  
  int i,j,len,num,key;
  long int bx,by,bm,bvx,bvy,bfx,bfy;
  long int nminx,nmaxx,nminy,nmaxy,nm,nmx,nmy,nch1,nch2,nch3,nch4;
  long int xmi,xma,ymi,yma;

  len = Galaxy->len;
  num = MyTree->numNode;
//parameters for bodies
  bx = 0;
  by = len;
  bm = len * 2;
  bvx = len * 3;
  bvy = len * 4;
  bfx = len * 5;
  bfy = len * 6;
//parameters for treenodes
  nminx = 0;
  nmaxx = num;
  nminy = num*2;
  nmaxy = num*3;
  nm = num*4;
  nmx = num*5;
  nmy = num*6;
  nch1 = num*7;
  nch2 = num*8;
  nch3 = num*9;
  nch3 = num*10;

  xmi = MyTree->Nodes[curIndex + nminx];
  xma = MyTree->Nodes[curIndex + nmaxx];
  ymi = MyTree->Nodes[curIndex + nminy];
  yma = MyTree->Nodes[curIndex + nmaxy];

//here we try to still insert the bodies that ran out of the region of the tree into root node and we enlarge the mass of root node to attract the bodies
  if(Galaxy->Bodies[bodyIndex + bx] < xmi || Galaxy->Bodies[bodyIndex + bx] > xma || Galaxy->Bodies[bodyIndex + by] < ymi || Galaxy->Bodies[bodyIndex + by] > yma){

    if(curLevel == 1){
        MyTree->Nodes[curIndex + nmx] = (MyTree->Nodes[curIndex + nmx] * MyTree->Nodes[curIndex + nm] + Galaxy->Bodies[bodyIndex + bx] * Galaxy->Bodies[bodyIndex + bm])/(MyTree->Nodes[curIndex + nm] + Galaxy->Bodies[bodyIndex + bm]);
        MyTree->Nodes[curIndex + nmy] = (MyTree->Nodes[curIndex + nmy] * MyTree->Nodes[curIndex + nm] + Galaxy->Bodies[bodyIndex + by] * Galaxy->Bodies[bodyIndex + bm])/(MyTree->Nodes[curIndex + nm] + Galaxy->Bodies[bodyIndex + bm]);
         MyTree->Nodes[curIndex + nm] += Galaxy->Bodies[bodyIndex + bm] * 200;

    }


    return;
  }

  //calculate the centre of mass and increase the mass of node 
  MyTree->Nodes[curIndex + nmx] = (MyTree->Nodes[curIndex + nmx] * MyTree->Nodes[curIndex + nm] + Galaxy->Bodies[bodyIndex + bx] * Galaxy->Bodies[bodyIndex + bm])/(MyTree->Nodes[curIndex + nm] + Galaxy->Bodies[bodyIndex + bm]);
  MyTree->Nodes[curIndex + nmy] = (MyTree->Nodes[curIndex + nmy] * MyTree->Nodes[curIndex + nm] + Galaxy->Bodies[bodyIndex + by] * Galaxy->Bodies[bodyIndex + bm])/(MyTree->Nodes[curIndex + nm] + Galaxy->Bodies[bodyIndex + bm]);
  MyTree->Nodes[curIndex + nm] += Galaxy->Bodies[bodyIndex + bm];
  

  //here im gonna do a recursion to inser the body further to the child
  if(curLevel < TREELEVEL){
    key = 0;
    if(Galaxy->Bodies[bodyIndex + bx] > (xmi + xma)/2) key += 1;
    if(Galaxy->Bodies[bodyIndex + by] > (ymi + yma)/2) key += 2;

    insertBody(bodyIndex, curIndex*4 + key+1, curLevel+1);

  }

}

//calculate the force of bodies
void forceBody(int bodyIndex, int curIndex, int curLevel){
  int i,len,num;
  long int bx,by,bm,bvx,bvy,bfx,bfy;
  long int nminx,nmaxx,nminy,nmaxy,nm,nmx,nmy,nch1,nch2,nch3,nch4;
  long int xmi,xma,ymi,yma;
  data_t x_dist, y_dist, dtsq, dist, nsize, force, m1, m2;

  len = Galaxy->len;
  num = MyTree->numNode;
//parameters for bodies
  bx = 0;
  by = len;
  bm = len * 2;
  bvx = len * 3;
  bvy = len * 4;
  bfx = len * 5;
  bfy = len * 6;
//parameters for treenodes
  nminx = 0;
  nmaxx = num;
  nminy = num*2;
  nmaxy = num*3;
  nm = num*4;
  nmx = num*5;
  nmy = num*6;
  nch1 = num*7;
  nch2 = num*8;
  nch3 = num*9;
  nch3 = num*10;

//node's xmin xmax ymin ymax
  xmi = MyTree->Nodes[curIndex + nminx];
  xma = MyTree->Nodes[curIndex + nmaxx];
  ymi = MyTree->Nodes[curIndex + nminy];
  yma = MyTree->Nodes[curIndex + nmaxy];
//calculate the distance
  x_dist = Galaxy->Bodies[bodyIndex + bx] - MyTree->Nodes[curIndex + nmx];
  y_dist = Galaxy->Bodies[bodyIndex + by] - MyTree->Nodes[curIndex + nmy];
  dtsq = x_dist*x_dist + y_dist*y_dist;
  dist = sqrt(dtsq);
  nsize = MyTree->Nodes[curIndex + nmaxx] - MyTree->Nodes[curIndex + nminx];


//calculation of force
  if(nsize/dist < THETA ){// case1, far enough
    if( dtsq > 1000 ){
      m1 = Galaxy->Bodies[bodyIndex + bm];
      m2 = MyTree->Nodes[curIndex + nm];
      force = (m1 * m2  * GRAVITYCONST * 6E10) / (dtsq);
      Galaxy->Bodies[bodyIndex + bfx] += (-x_dist/dist)*force;//(x_dist/dist)*force;
      Galaxy->Bodies[bodyIndex + bfy] += (-y_dist/dist)*force;//(y_dist/dist)*force;
    }
  }
   
  else if(curLevel < TREELEVEL){//case2 , not far enough but can be splited
    forceBody(bodyIndex, curIndex*4+1, curLevel+1);
    forceBody(bodyIndex, curIndex*4+2, curLevel+1);
    forceBody(bodyIndex, curIndex*4+3, curLevel+1);
    forceBody(bodyIndex, curIndex*4+4, curLevel+1);
  }

  else if(nsize/dist >= THETA){//case3 , not far enough but already the smallest cell, here we calculate it by its centre of mass , but it should be done in brute-force...
    if( dtsq > 1000 ){

      m1 = Galaxy->Bodies[bodyIndex + bm];
      m2 = MyTree->Nodes[curIndex + nm];
      force = (m1 * m2  * GRAVITYCONST * 6E10) / (dtsq);
      Galaxy->Bodies[bodyIndex + bfx] += (x_dist/dist)*force;
      Galaxy->Bodies[bodyIndex + bfy] += (y_dist/dist)*force;

    }
  }

}

/**************************************/
//the quad tree func for cpu barnes-hut
//construct tree, insert to tree, calculate the force and velocity and next position of bodies
void quadTree(){

  void reset_tree();
  reset_tree();// we reset the tree at every new time interval

  int i,j,len,num;
  len = Galaxy->len;
  num = MyTree->numNode;

  long int bx,by,bm,bvx,bvy,bfx,bfy;

  
  bx = 0;
  by = len;
  bm = len * 2;
  bvx = len * 3;
  bvy = len * 4;
  bfx = len * 5;
  bfy = len * 6;




  //insert bodies to the tree
  for(i = 0; i < len; i++){
    insertBody(i,0,1);
  }

  //compute force
  for(j = 0; j < len; j++){
    Galaxy->Bodies[j + bfx] = 0;
    Galaxy->Bodies[j + bfy] = 0;
    forceBody(j,0,1);
  }


  //apply forces
  for( i = 0 ; i < len ; i++){

    Galaxy->Bodies[i + bvx] += Galaxy->Bodies[i + bfx] * TIMESTEP / Galaxy->Bodies[i + bm]; //set vx += fx /m
    Galaxy->Bodies[i + bvy] += Galaxy->Bodies[i + bfy] * TIMESTEP / Galaxy->Bodies[i + bm]; //set vy += fy /m

    Galaxy->Bodies[i + bx] += Galaxy->Bodies[i + bvx] * TIMESTEP; //new x +=vx
    Galaxy->Bodies[i + by] += Galaxy->Bodies[i + bvy] * TIMESTEP; //new y +=vy

  }

}