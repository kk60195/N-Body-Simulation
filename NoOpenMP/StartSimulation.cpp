#include "StartSimulation.h"
#include "Body.h"
#include "QuadNode.h"
#include <GL/glut.h>
#include <omp.h>

#include <string>
#include <time.h> 
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */      
#include <iostream>
#include <vector>

using namespace std;

#define TIMETORUN 50

//CUDA
const int N = 16; 
const int blocksize = 16; 

__global__ 
void hello(char *a, int *b) 
{
	a[threadIdx.x] += b[threadIdx.x];
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

omp_set_num_threads(4);

#pragma omp parallel shared(myList) private(i)
#pragma omp for

	for(int i = 0 ; i < count ; i++){
		myList[i].resetForce();

		myList[i].calcForce(tree);
		//printf("\nafter calc");
		//myList[i]->toString();
		myList[i].calcPosition(10);
		//myList[i].toString();	
	}


	
}
