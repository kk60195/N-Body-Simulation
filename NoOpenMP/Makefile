OBJS = main.o Body.o StartSimulation.o QuadNode.o
CC = g++

#cuda g++ version
NCC = nvcc

DEBUG = -g

#nvcc doesnt have -wall
#CFLAGS = -Wall -c $(DEBUG) 
#LFLAGS = -Wall $(DEBUG) -fopenmp
CFLAGS =  -c $(DEBUG)
LFLAGS =  $(DEBUG) 

#openGL Flags
GLFLAGS =  -lGL -lglut -lGLU -lrt

#Cuda flags
NVFLAG = -L /usr/local/cuda/lib -lcudart

#OpenMP needs special flag to pass into xCompiler
OMPFLAG = -Xcompiler -fopenmp 

all: main

main: $(OBJS)
	$(NCC)  $(OMPFLAG) $(LFLAGS) $(OBJS) -o main $(GLFLAGS) 

Body.o : Body.h Body.cpp
	$(NCC) $(CFLAGS) Body.cpp

StartSimulation.o : StartSimulation.h StartSimulation.cu
	$(NCC) $(NVLFAG) $(CFLAGS) StartSimulation.cu $(GLFLAGS)

QuadNode.o : QuadNode.h QuadNode.cpp
	$(NCC) $(CFLAGS) QuadNode.cpp


clean:
	\rm *.o *~ main