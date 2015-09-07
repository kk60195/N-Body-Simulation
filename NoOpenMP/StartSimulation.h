#ifndef	STARTSIMULATION_H
#define STARTSIMULATION_H

#include "Body.h"
#include "QuadNode.h"

#include <vector>
#include <stdlib.h>



class StartSimulation{

protected:
	
	int numOfBodies;

	Body *myBodies;
	QuadNode *mytree;
	Body **convertedBodies;
	
	//void run();
	void draw();


public:
	StartSimulation(int count,int x, int y);
	Body GetBody(int place);
	void TreeRun(int count, Body *myList, QuadNode *tree);
	void TreeRunOpenMP(int count, Body *myList, QuadNode *tree);
	void run(int choice);



};

#endif

