OBJS = main.o Body.o StartSimulation.o QuadNode.o
CC = g++
DEBUG = -g
CFLAGS = -Wall -c $(DEBUG) 
LFLAGS = -Wall $(DEBUG)
GLFLAGS =  -lGL -lglut 


all: main

main: $(OBJS)
	$(CC) $(LFLAGS) $(OBJS) -o main $(GLFLAGS) 

Body.o : Body.h Body.cpp
	$(CC) $(CFLAGS) Body.cpp

StartSimulation.o : StartSimulation.h StartSimulation.cpp
	$(CC) $(CFLAGS) StartSimulation.cpp $(GLFLAGS)

QuadNode.o : QuadNode.h QuadNode.cpp
	$(CC) $(CFLAGS) QuadNode.cpp


clean:
	\rm *.o *~ main