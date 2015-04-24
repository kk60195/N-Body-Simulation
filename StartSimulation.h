#ifndef	STARTSIMULATION_H
#define STARTSIMULATION_H

#include "Body.h"

#include <vector>

#include <stdlib.h>



class StartSimulation{

protected:
	
	int numOfBodies;

	Body *myBodies;
	
	//void run();
	void draw();

public:
	StartSimulation(int count);
	Body GetBody(int place);
	void run();



};

#endif

