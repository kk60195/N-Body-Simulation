#ifndef	STARTSIMULATION_H
#define STARTSIMULATION_H

#include "Body.h"

#include <vector>

#include <stdlib.h>





class StartSimulation{

protected:
	
	int numOfBodies;

	std::vector<Body> myBodies;
	
	void run();

public:
	StartSimulation(int count);
	//StartSimulation(int count);
	//void showBodies();
	



};

#endif

