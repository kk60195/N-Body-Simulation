#include "StartSimulation.h"
#include "Body.h"

#include <string>
#include <time.h> 
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */      
#include <iostream>
#include <vector>

using namespace std;

#define TIMETORUN 10;


	

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

	for(i = 0; i < count; i++){

		ina = rand()%1000;//x
		inb = rand()%1000;//y
		inc = rand()%1000;//mass

		myList[i] = new Body(ina,inb,0.0,0.0,inc);
		
		printf("%d) ",i + 1);
		myList[i]->toString();


		myBodies.push_back(myList[i]);
		//(Body*)(BodyList + i) = new Body(ina,inb,0.0,0.0,inc);
	}
	//this->myBodies[] = new Body[count];
	
	printf("\nInitialize Bodies done!\n");

	//start timestep
	//this->run();


}

void StartSimulation::run(){

	int i,j,count;
	count = 0;
	for(i = 0 ; i < this->numOfBodies ; i++){
		//this->myBodies[i]->resetForce();
		for(j = 0 ; j< this->numOfBodies ; j++){
			if(i!=j){
			//this->myBodies[i]->addForce(*this->myBodies[j]);
			count++;
		}
		}

		
	}
	//myBodies[1]->toString();
	printf("\ncount ran for: %d\n", count);

	//for(i = 0; i < this-> numOfBodies ; i++){
	//	this->myBodies[i].update(1);
	//	myBodies[i].toString();
	//}





}

