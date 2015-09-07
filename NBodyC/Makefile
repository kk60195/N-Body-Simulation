OBJS = main.cu
OBJSCUDA = main.cu
CC = gcc

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

main: $(OBJSCUDA)
	$(NCC)  $(OMPFLAG) $(LFLAGS) $(OBJS) -o main $(GLFLAGS) 

#NBody.o : NBody.h NBody.c
#	$(NCC) $(NVLFAG) $(CFLAGS) Body.cu $(GLFLAGS) 




clean:
	\rm *.o *~ main