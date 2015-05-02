OBJS = main.o Body.o StartSimulation.o QuadNode.o
CC = g++
NCC = nvcc
DEBUG = -g
#CFLAGS = -Wall -c $(DEBUG) 
#LFLAGS = -Wall $(DEBUG) -fopenmp
CFLAGS =  -c $(DEBUG)
LFLAGS =  $(DEBUG) 
GLFLAGS =  -lGL -lglut -lGLU -lrt
NVFLAG = -L /usr/local/cuda/lib -lcudart
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