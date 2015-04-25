#include "Body.h"
#include <iostream>
#include <string>
#include <sstream>
#include <stdio.h>
#include <math.h>
#include <time.h> 
#include <stdlib.h>     /* srand, rand, abs */   


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


		//calculate velocity
		this->vx += this->fx * time / this->mass;
		this->vy += this->fy * time / this->mass;

		//apply velocity to a time step
		this->x += vx * time;
		this->y += vy * time;

		}
		double Body::distanceTo(Body b){

			double x_dist = this->x - b.x;
    		double y_dist = this->y - b.y;
    		double r_Squared = (x_dist*x_dist)  + (y_dist*y_dist); 
    		double dist = sqrt(r_Squared);
			return dist;
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
    		
    				double dist = this->distanceTo(b);

    				    //threashhold zone
    					if(dist > 10){

    						Force = (  this->mass * b.mass )/ (dist* dist * this->AddCount);
    						this->fx -= Force * x_dist ;/// dist;
    						this->fy -= Force * y_dist ;/// dist;

    					}		


		}
		void Body::toString(){
		
			printf("Mass:%.1f\tPosition:%.1f,%.1f\tVelocity:%.1f,%.1f Force::%.1f,%.1f\n",this->mass, this->x,this->y,this->vx,this->vy,this->fx,this->fy);
			
		}

void Body::calcForce(QuadNode* node){
    double dx = node->mx - this->x;
    double dy = node->my - this->y;
    double d2 = dx * dx + dy * dy;
    double d = sqrt(d2); //distance from quadnode's center to target body
    double h = node->ymax - node->ymin; //height of the quadnode
    double r = h/d;
    
    if(d < 30){
        
    }
    else if(!node->isactive){
        
    }

    else if(node->isparent && r >= THETA){
        //printf("here\n");
       ///We need to separate to four smaller nodes for this quadnode and calculate recursively

         for(int i = 0; i < 4; i++){
                if(node->myChildren[i]!=NULL)
                   this-> calcForce(node->myChildren[i]);
                
            }         
    }
    else{ //The condition that we only have one body in the quadnode
        //printf("fx: %lf\n",this->fx);

            this->fx += (dx/d)* (node->m * this->mass /(d2 * 200));
            this->fy += (dy/d)* (node->m * this->mass / (d2 * 200));
           
    }
    
}

void Body::calcPosition(double time){

        this->vx += this->fx * time / this->mass;
        this->vy += this->fy * time / this->mass;

        this->x += vx * time;
        this->y += vy * time;
}