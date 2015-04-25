#include "Body.h"
#include <iostream>
#include <string>
#include <sstream>
#include <stdio.h>
#include <math.h>
#include <time.h> 
#include <stdlib.h>     /* srand, rand, abs */   


#define SOFT 10E11

using namespace std;

	Body::Body(){
		this->x = 0;
		this->y = 0;
		this->mass = 0;
		this->r = 200;//rand()%255;
		this->g = 200;//rand()%255;
		this->b = 200;//rand()%255;
		this->AddCount = 0;

	}
	Body::Body(double x,double y,double vx,double vy, double mass){
		this->x = x;
		this->y = y;
		this->mass = mass;
		this->r = rand()%255;
		this->g = rand()%255;
		this->b = rand()%255;

	}

	void Body::update(double time){
		
		this->vx += this->fx * time / this->mass;
		this->vy += this->fy * time / this->mass;

		//printf("\nvx %d", (vx * time) );

		this->x += vx * time;
		this->y += vy * time;


		//if(this->x > 6000) this-> x =6000;
		//if(this->x < 0) this-> x = 0;
		//if(this->y > 6000) this->y=6000;
		//if(this->y < 0) this->y =0;
		
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
    			
    			//if(this->x != b.x && this->y != b.y){

     			// count number of forces added
     			int count;

     			if(this->fx == 0)
     				if(this->fy == 0)
     					count = 0;

     			count++;

     			if(count > this->AddCount) this->AddCount = count;

     			    double x_dist = this->x - b.x;
    				double y_dist = this->y - b.y;
    				
    
   				 //calculate the distance between the two objects r^2 = x^2 + y^2 + z^2
    				double r_Squared = (x_dist*x_dist)  + (y_dist*y_dist);  
    				//printf("\nr_squared = %.1f",r_Squared);
    		
    				double dist = sqrt(r_Squared);



    				if( r_Squared != 0){
    					if(dist > 100){
    				Force = (  this->mass * b.mass )/ (dist* dist * this->AddCount);
    				


    				this->fx -= Force * x_dist ;/// dist;
    				this->fy -= Force * y_dist ;/// dist;
    					}
    				//printf("\nforce = %.1f this->mass %.1f\n ",Force,this->mass);
    				}

    				/*
    				if(x_dist < 0)
    				this->fx -= Force * x_dist ;/// dist;

      				if(x_dist > 0)
    				this->fx += Force * x_dist ;/// dist;
    			    
    			   
    				if(y_dist < 0)
    				this->fy -= Force * y_dist ;/// dist;

    				if(y_dist > 0)
    				this->fy += Force * y_dist ;/// dist;
					*/
					
    				//printf("\nfx:%.1f fy: %.1f\n",this->fx,this->fy);

    				//if(this->fx > 1800) this->fx = 1800;
    				//if(this->fx < -1800) this->fx = -1800;
    				//if(this->fy > 1800) this->fy = 1800;
    				//if(this->fy < -1800) this->fy = -1800;

    				  //printf("\nforces:%f %f", this->fx , this->fy);

  
    

    			


		}
		void Body::toString(){
		
			printf("Mass:%.1f\tPosition:%.1f,%.1f\tVelocity:%.1f,%.1f Force::%.1f,%.1f\n",this->mass, this->x,this->y,this->vx,this->vy,this->fx,this->fy);
			
		}
