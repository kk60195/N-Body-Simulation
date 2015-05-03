#include "StartSimulation.h"
#include "Body.h"
#include "QuadNode.h"
#include <GL/glut.h>
#include <omp.h>

#include "cuPrintf.cu"

#include <string>
#include <time.h> 
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */      
#include <iostream>
#include <vector>

using namespace std;

#define TIMETORUN 50


//// nvcc hello-world.cu -L /usr/local/cuda/lib -lcudart -o hello-world
//CUDA
const int N = 16; 
const int blocksize = 16; 

__global__ 
void hello(char *a, int *b) 
{
	a[threadIdx.x] += b[threadIdx.x];
	int myid = blockIdx.x;
	cuPrintf("hello%d\n", myid);
}

__global__ 
void ComputeForce(Body* Bodies) 
{
	//a[threadIdx.x] += b[threadIdx.x];
	int myid = blockIdx.x;
	int j;
	double x_dist,y_dist;
	double r_Squared;
	double dist;
	double Force;
	cuPrintf("hello%d\n", myid);


	Bodies[myid].fx = 0;
	Bodies[myid].fy = 0;

	for(j = 0 ; j< gridDim.x; j++){

				if(myid!=j){
					
					    x_dist = Bodies[myid].x - Bodies[j].x;
						y_dist = Bodies[myid].y - Bodies[j].y;
						r_Squared = (x_dist*x_dist)  + (y_dist*y_dist);
						dist = sqrt(r_Squared);

						if(dist > 10){

							Force = (Bodies[myid].mass * Bodies[j].mass )/ (dist *dist * gridDim.x * gridDim.x * gridDim.x);
							Bodies[myid].fx -= Force * x_dist ;/// dist;
							Bodies[myid].fy -= Force * y_dist ;/// dist;

						}
				}
	}


 __syncthreads();

	for(j = 0 ; j< gridDim.x; j++){
		Bodies[myid].vx += Bodies[myid].fx / Bodies[myid].mass;
        Bodies[myid].vy += Bodies[myid].fy / Bodies[myid].mass;

        Bodies[myid].x += Bodies[myid].vx;
        Bodies[myid].y += Bodies[myid].vy;
	}	
}


	

StartSimulation::StartSimulation(int count,int x, int y){
	//cuda
	char a[N] = "Hello \0\0\0\0\0\0";
	int b[N] = {15, 10, 6, 0, -11, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

	char *ad;
	int *bd;
	const int csize = N*sizeof(char);
	const int isize = N*sizeof(int);

	printf("%s", a);

	cudaMalloc( (void**)&ad, csize ); 
	cudaMalloc( (void**)&bd, isize ); 
	cudaMemcpy( ad, a, csize, cudaMemcpyHostToDevice ); 
	cudaMemcpy( bd, b, isize, cudaMemcpyHostToDevice ); 
	
	dim3 dimBlock( blocksize, 1 );
	dim3 dimGrid( 1, 1 );
	hello<<<dimGrid, dimBlock>>>(ad, bd);
	cudaMemcpy( a, ad, csize, cudaMemcpyDeviceToHost ); 
	cudaFree( ad );
	cudaFree( bd );
	
	printf("%s\n", a);




	//Body *myBodies[256];
	this->numOfBodies = count;

	int i;
	double ina,inb,inc;
	time_t seconds;
	time(&seconds);
	srand((unsigned int) seconds);
	
	//temporary
	Body *myList [count];

	//QuadTree
	this->mytree = new QuadNode(0,x,0,y);

	//this->myBodies = myList[0];
	myBodies = new Body[count];

	for(i = 0; i < count; i++){

		ina = rand()%x;//x
		inb = rand()%y;//y
		inc = rand()%1000;//mass

		myList[i] = new Body(ina,inb,0.0,0.0,inc);
	
		this->myBodies[i] = *myList[i];

		//delete *myList;	

	}
	//this->myBodies = *myList;
	
	
	printf("\nInitialize Bodies done!\n");


	//start timestep
	
	for(i = 0; i < TIMETORUN ; i++){



	}




}

void StartSimulation::run(int choice){
	
	if(choice == 0){
	int i,j;
		
		for(i = 0 ; i < this->numOfBodies ; i++){

			this->myBodies[i].resetForce();
		
			for(j = 0 ; j< this->numOfBodies ; j++){

				if(i!=j){
					this->myBodies[i].addForce(this->myBodies[j]);
				}
			}
			this->myBodies[i].update(1);
		}

	
	}

	else if(choice == 1){
		int count = this->numOfBodies;
		this->convertedBodies = &myBodies;
		TreeRun(count, this->myBodies, this->mytree);
		
	}
	//OpenMP
	else if(choice == 2){
		int count = this->numOfBodies;
		this->convertedBodies = &myBodies;
		TreeRunOpenMP(count, this->myBodies, this->mytree);
	}

	//brute force CUDA
	else if(choice == 3){

		//char a[N] = "Hello \0\0\0\0\0\0";
		//int b[N] = {15, 10, 6, 0, -11, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

		Body *CBody;
		const int CSize = this->numOfBodies * sizeof(Body);

		cudaMalloc( (void**)&CBody, CSize);

		cudaMemcpy(CBody, this->myBodies,CSize, cudaMemcpyHostToDevice);

		dim3 dimBlock(1,1);
		dim3 dimGrid(this->numOfBodies,1);

		ComputeForce<<<dimGrid,dimBlock>>>(CBody);

		cudaMemcpy(this->myBodies,CBody,CSize, cudaMemcpyDeviceToHost);


		cudaFree(CBody);
		/*
		printf("%s", a);

		cudaMalloc( (void**)&ad, csize ); 
		cudaMalloc( (void**)&bd, isize ); 
		cudaMemcpy( ad, a, csize, cudaMemcpyHostToDevice ); 
		cudaMemcpy( bd, b, isize, cudaMemcpyHostToDevice ); 
	
		dim3 dimBlock( blocksize, 1 );
		dim3 dimGrid( 1, 1 );
		hello<<<dimGrid, dimBlock>>>(ad, bd);
		cudaMemcpy( a, ad, csize, cudaMemcpyDeviceToHost ); 
		cudaFree( ad );
		cudaFree( bd );
	
		printf("%s\n", a);
		*/
	

	}



}

Body StartSimulation::GetBody(int i){
	return this->myBodies[i];
}

void StartSimulation::TreeRun(int count, Body *myList, QuadNode *tree)
{
	tree->clearNode();
	//this->mytree = new QuadNode(0,x,0,y);
	Body *tempList;
	for(int i = 0 ; i < count ; i++){
		tempList = &myList[i];
		tree->addBody(tempList);
		// printf("\nafter insert");
		// myList[i]->toString();			
	}


	for(int i = 0 ; i < count ; i++){
		myList[i].resetForce();

		myList[i].calcForce(tree);
		//printf("\nafter calc");
		//myList[i]->toString();
		myList[i].calcPosition(10);
		//myList[i].toString();	
	}


	
}
void StartSimulation::TreeRunOpenMP(int count, Body *myList, QuadNode *tree)
{
	tree->clearNode();
	//this->mytree = new QuadNode(0,x,0,y);
	Body *tempList;
	for(int i = 0 ; i < count ; i++){
		tempList = &myList[i];
		tree->addBody(tempList);
		// printf("\nafter insert");
		// myList[i]->toString();			
	}

//omp_set_num_threads(4);

//#pragma omp parallel shared(myList) private(i)
//#pragma omp for

	for(int i = 0 ; i < count ; i++){
		myList[i].resetForce();

		myList[i].calcForce(tree);
		//printf("\nafter calc");
		//myList[i]->toString();
		myList[i].calcPosition(10);
		//myList[i].toString();	
	}


	
}
