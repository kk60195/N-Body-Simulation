#include "Body.h"
#include <iostream>
#include <string>
#include <sstream>
#include <stdio.h>
#include <math.h>

#define SOFT 35E10

using namespace std;

	Body::Body(double x,double y,double vx,double vy, double mass){
		this->x = x;
		this->y = y;
		this->mass = mass;

	}

		void Body::update(double time){
		
		this->vx += this->fx * time / this->mass;
		this->vy += this->fy * time / this->mass;

		this->x += vx * time;
		this->y += vy * time;

		}
		double Body::distanceTo(Body b){
			return 3;
		}
		void Body::resetForce(){
			this->fx= 0;
			this->fy= 0;
	
		}
		void Body::addForce(Body b){
			//this->resetForce();
			
			/*F = G m1*m2 / r^2  
     			G = gravitational constant | G = 6.67300 × 10^−11
     			m1 = mass 1 (kg)
     			m2 = mass 2 (kg)
     			r = distance between the centers of the masses*/
    
    			//find the distance between the x y pairs 

    			//make sure its not itself
    			if(true){
    			//if(this->x != b.x && this->y != b.y){

     			    double x_dist = this->x - b.x;
    				double y_dist = this->y - b.y;
    				
    
   				 //calculate the distance between the two objects r^2 = x^2 + y^2 + z^2
    				double r_Squared = (x_dist*x_dist)  + (y_dist*y_dist);  
    				//printf("\nr_squared = %.1f",r_Squared);
    				if( r_Squared != 0){
    				Force = (G* this->mass * b.mass *SOFT)/ (r_Squared);
    				//printf("\nforce = %.1f this->mass %.1f\n ",Force,this->mass);
    				}

    				double dist = sqrt(x_dist * x_dist + y_dist * y_dist);

    				this->fx += Force * x_dist / dist;
    				this->fy += Force * y_dist / dist;
    				//printf("\nfx:%.1f fy: %.1f\n",this->fx,this->fy);

    			}


		}
		void Body::toString(){
		
			printf("Mass:%.1f\tPosition:%.1f,%.1f\tVelocity:%.1f,%.1f Force::%.1f,%.1f\n",this->mass, this->x,this->y,this->vx,this->vy,this->fx,this->fy);
			
		}
