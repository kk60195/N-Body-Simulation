#ifndef BODY_H
#define BODY_H

#include <string> 

#include "QuadNode.h"
#define THETA 0.1



class QuadNode;


class Body{

	private:
		 static const double G = 6.673e-11;

	public:
		double x,y;
		double vx,vy;
		double fx,fy;
		double ax,ay;
		double mass;
		double Force;
		unsigned char r,g,b;
		int AddCount;

		Body();
		Body(double x,double y,double vx,double vy, double mass);
		void update(double time);
		double distanceTo(Body b);
		void resetForce();
		void addForce(Body b);
		void toString();
		void calcForce(QuadNode* node);
		void calcPosition(double time);




};



#endif