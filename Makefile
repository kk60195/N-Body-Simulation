OBJS = main.o Body.o
CC = g++
DEBUG = -g
CFLAGS = -Wall -c $(DEBUG)
LFLAGS = -Wall $(DEBUG)

all: main

main: $(OBJS)
	$(CC) $(LFLAGS) $(OBJS) -o main

Body.o : Body.h Body.cpp
	$(CC) $(CFLAGS) Body.cpp


clean:
	\rm *.o *~ main