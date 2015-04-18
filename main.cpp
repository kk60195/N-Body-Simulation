//g++ -O2 -o main main.cpp
#include <iostream>
#include <string>
#include <time.h> 
#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */      

#include "Body.h"
#include "StartSimulation.h"

#define GRIDSIDES 1000
#define NUMBODY 10
#define MAXMASS 20



using namespace std;

int main(int argc, char const *argv[])
{
	int i,j,k;
	double ina,inb,inc;
	time_t seconds;
	time(&seconds);
	srand((unsigned int) seconds);
	
	Body *myList [10];




	for(i = 0; i < 10; i++){

		ina = rand()%1000;
		inb = rand()%1000;
		inc = rand()%1000;

		//printf("rand is %f\n", ina);
		myList[i] = new Body(ina,inb,0.0,0.0,inc);
		myList[i]->toString();
	}


	//Body *n1 = new Body(40.0,40.0,0.0,0.0,50.0);

	//n1->toString();
	/* code */
	return 0;
}