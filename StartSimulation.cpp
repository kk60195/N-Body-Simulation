#include "StartSimulation.h"
#include "Body.h"
#include "QuadNode.h"
#include <GL/glut.h>

#include <string>
#include <time.h> 
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */      
#include <iostream>
#include <vector>

using namespace std;

#define TIMETORUN 50


	

StartSimulation::StartSimulation(int count,int x, int y){



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
	

		//error here
		this->myBodies[i] = *myList[i];

<<<<<<< HEAD
		printf("%d) ",i + 1);
		myList[i]->toString();
		delete *myList;	
=======
		//printf("%d) ",i + 1);
		//myList[i]->toString();
		
>>>>>>> cea23cca8f68aecf88d0ce841921f91fe7c119a8
	}
	
	
	
	printf("\nInitialize Bodies done!\n");


	//start timestep
	
	for(i = 0; i < TIMETORUN ; i++){

	//this->run();

	}

   // for (i = 0; i < count; i++)
    //{
    //    delete myList[i];
    //}


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
		//printf("\n1)");
		//myBodies[0].toString();
		//printf("\n2)");
		//myBodies[1].toString();

		
	}

	
	
		for(i = 0; i < this-> numOfBodies ; i++){
			this->myBodies[i].update(1);
		
		}


	}
	if(choice == 1){
		int count = this->numOfBodies;
		this->convertedBodies = &myBodies;
		TreeRun(count, this->myBodies, this->mytree);
		//delete myList;
	}



}

Body StartSimulation::GetBody(int i){

	return this->myBodies[i];

}

void StartSimulation::TreeRun(int count, Body *myList, QuadNode *tree)
{
	tree->clearNode();
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