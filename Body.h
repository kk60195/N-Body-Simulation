#ifndef BODY_H
#define BODY_H

#include <string> 


class Body{

	private:
		 static const double G = 6.673e-11;

	public:
		double x,y;
		double vx,vy;
		double fx,fy;
		double mass;

		Body(double x,double y,double vx,double vy, double mass);
		void update(double time);
		double distanceTo(Body b);
		void resetForce();
		void addForce(Body b);
		void toString();




};



#endif