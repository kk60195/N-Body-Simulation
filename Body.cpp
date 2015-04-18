#include "Body.h"
#include <iostream>
#include <string>
#include <sstream>
#include <stdio.h>

using namespace std;

	Body::Body(double x,double y,double vx,double vy, double mass){
		this->x = x;
		this->y = y;
		this->mass = mass;

	}

		void Body::update(double time){

		}
		double Body::distanceTo(Body b){
			return 3;
		}
		void Body::resetForce(){

		}
		void Body::addForce(Body b){

		}
		void Body::toString(){
		
			printf("Mass:%.1f\tPosition:%.1f,%.1f\tVelocity:%.1f,%.1f\n",this->mass, this->x,this->y,this->vx,this->vy);
			
		}
