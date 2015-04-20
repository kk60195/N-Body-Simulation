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
	int count;
	if (argc > 1)
    {   
    count = atoi( argv[1] );

	StartSimulation s1(count);
    }
	else{
	StartSimulation s1(5);
	}
	
	return 0;
}