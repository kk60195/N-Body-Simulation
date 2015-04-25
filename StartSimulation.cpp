#include "StartSimulation.h"
#include "Body.h"
#include <GL/glut.h>

#include <string>
#include <time.h> 
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */      
#include <iostream>
#include <vector>

using namespace std;

#define TIMETORUN 50


	

StartSimulation::StartSimulation(int count){



	//Body *myBodies[256];
	this->numOfBodies = count;

	int i;
	double ina,inb,inc;
	time_t seconds;
	time(&seconds);
	srand((unsigned int) seconds);


	
	//temporary
	Body *myList [count];

	//this->myBodies = myList[0];
	myBodies = new Body[count];

	for(i = 0; i < count; i++){

		ina = rand()%800;//x
		inb = rand()%800;//y
		inc = rand()%1000;//mass

		myList[i] = new Body(ina,inb,0.0,0.0,inc);
	

		//error here
		this->myBodies[i] = *myList[i];

		printf("%d) ",i + 1);
		myList[i]->toString();
		
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

void StartSimulation::run(){

	int i,j;
	
	for(i = 0 ; i < this->numOfBodies ; i++){

		this->myBodies[i].resetForce();
		

		for(j = 0 ; j< this->numOfBodies ; j++){

			if(i!=j){
			this->myBodies[i].addForce(this->myBodies[j]);
			
			}

		}
		printf("\n1)");
		myBodies[0].toString();
		printf("\n2)");
		myBodies[1].toString();

		
	}

	

	
	//printf("\ncount ran for: %d\n", count);
	
	for(i = 0; i < this-> numOfBodies ; i++){
		this->myBodies[i].update(1);
		
	}
	




}

Body StartSimulation::GetBody(int i){

	return this->myBodies[i];

}

