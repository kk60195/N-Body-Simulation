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
		this->x += vx * time;
		this->y += vy * time;

		}
		double Body::distanceTo(Body b){
			return 3;
		}
		void Body::resetForce(){
			this->x = 0;
			this->y = 0;
			this->vx = 0;
			this->vy = 0;
			this->ax = 0;
			this->ay = 0;

		}
		void Body::addForce(Body b){
			/*F = G m1*m2 / r^2  
     			G = gravitational constant | G = 6.67300 × 10^−11
     			m1 = mass 1 (kg)
     			m2 = mass 2 (kg)
     			r = distance between the centers of the masses*/
    
    			//find the distance between the x y pairs 
     			    double x_dist = this->x - otherObject.x;
    				double y_dist = this->y - otherObject.y;
    				
    
   				 //calculate the distance between the two objects r^2 = x^2 + y^2 + z^2
    				double r_Squared = ((x_dist*x_dist)  + (y_dist*y_dist) + (z_dist*z_dist));  

    			


		}
		void Body::toString(){
		
			printf("Mass:%.1f\tPosition:%.1f,%.1f\tVelocity:%.1f,%.1f\n",this->mass, this->x,this->y,this->vx,this->vy);
			
		}
