/**
*this file defines the quadtree
**/

#include "QuadNode.h"
#include "Body.h"

#include <iostream>
using std::cerr;
using std::cout;
#include <cmath>

QuadNode::QuadNode(double x1, double x2, 
		double y1, double y2)
	// xmin(x1),
	// xmax(x1),
	// ymin(y1),
	// ymax(y2),
	// mx(0),
	// my(0),
	// m(0),
	// theta(1.0),
	// isactive(false), //should be false, because we'll have empty quadnode initially
	// isparent(false),
	// me(NULL),
	// myChildren(NULL)
{
	this->xmin=x1;
	this->xmax=x2;
	this->ymin=y1;
	this->ymax=y2;
	this->mx=0;
	this->my=0;
	this->m=0;
	this->theta=1.0;
	this->isactive=false; //should be false, because we'll have empty quadnode initially
	this->isparent=false;
	this->me=NULL;
	this->myChildren=NULL;
}



//deconstruction the quadnode
QuadNode::~QuadNode()
{
	this->clearNode();
}

void QuadNode::addBody(Body* body)
{
	if(this->getQuadrant(body)==5){
		return;
	}

	//If this quadnode does not have a body in it, just add new body and return.
	if(!this->isactive){
		this->me = body;
		this->mx = body->x;
		this->my = body->y;
		this->m = body->mass;
		this->isactive= true;
		return;
	}
	//if it is not empty
	//if it is a leaf node, just divide it
	//if it is not, look into its corresponding child
	if(!this->isparent){
		this->createChildren();

		this->myChildren[this->getQuadrant(body)]->addBody(body);
		this->myChildren[this->getQuadrant(me)]->addBody(me);
		this->me = NULL;

		this->calcMass();
	}else{

		this->myChildren[this->getQuadrant(body)]->addBody(body);
		//this->myChildren[getQuadrant(me)] = addBody(me);


		this->calcMass();
	}

}

/*
QuadNode::addAllBody (BodySystem* bs){

}
*/

void QuadNode::clearNode (){

	//if it is not active, no need to change
	if(!this->isactive)
		return;
	//clear the node's attribute
	this->me = NULL;
	this->m = 0;
	this->mx = 0;
	this->my = 0;
	this->isactive = false;

	if(!this->isparent)
		return;

	//delete all the children
	for(unsigned int i=0;i<4;i++){
		if(this->myChildren[i] != NULL){
			delete this->myChildren[i];
			this->myChildren[i] = NULL;
		}
	}

	this->isparent = false;
}



void QuadNode::calcMass(){
	
	if(!this->isactive)
		return;
	if(!this->isparent)
		return;
	//reset the center of mass and total mass to 0
	this->mx=0;
	this->my=0;
	this->m=0;

	//calculate from the children's mass & centre of mass
	for(unsigned int i=0;i<4;i++){
		if(this->myChildren[i]->isactive){
			//If there is a body in myChildren[i],add up the mass and mass*position
			this->m += this->myChildren[i]->m;
			this->mx += (this->myChildren[i]->m) * (this->myChildren[i]->mx);
			this->my += (this->myChildren[i]->m) * (this->myChildren[i]->my);			
		}
	}

	this->mx /= this->m;
	this->my /= this->m;
}


// void QuadNode::calcForce(Body* body){
//     double dx = this->mx - body->x;
//     double dy = this->my - body->y;
//     double d2 = dx * dx + dy * dy;
//     double d = sqrt(d2); //distance from quadnode's center to target body
//     double h = this->ymax - this->ymin; //height of the quadnode
//     double r = h/d;
//     if(this->isparent){
//        if(r >= theta)
//         {//We need to separate to four smaller nodes for this quadnode and calculate recursively
//             for(int i = 0; i < 4; i++){
//                 if(this->myChildren[i]!=NULL){
//                    this->myChildren[i] -> calcForce(body);
//                 }
//             }
//          return;
//         }else{
//             //The condition that we can consider the quadnode as a whole when calculating force
//             body->fx = (dx/d)* (this->m * body->mass /d2);
//             body->fy = (dy/d)* (this->m * body->mass /d2);
//             return;
//         }
//     }else{ //The condition that we only have one body in the quadnode
//         body->fx = (dx/d)* (this->m * body->mass /d2);
//         body->fy = (dy/d)* (this->m * body->mass /d2);  
//         return;      
//     }
    
// }

/*
QuadNode::calAllForce(BodySystem* bs){

}
*/

unsigned int QuadNode::getQuadrant(Body* body){
    //0,1,2,3 means the four quadrant, 5 means that this body does not fit in this quadnode
	
	if((body->x >= this->xmin) && (body->x <= (this->xmin + this->xmax)/2)){
		if((body->y >= this->ymin) && (body->y <= (this->ymin + this->ymax)/2)){
			return 3;
		}else if((body->y > (this->ymin + this->ymax)/2) && (body->y <= this->ymax)){
			return 0;
		}else return 5;
	}else if((body->x > (this->xmin + this->xmax)/2) && (body->x <= this->xmax)){
		if((body->y >= this->ymin) && (body->y <= (this->ymin + this->ymax)/2)){
			return 2;
		}else if((body->y > (this->ymin + this->ymax)/2) && (body->y <= this->ymax)){
			return 1;
		}else return 5;
	}else return 5;
}


void QuadNode::createChildren(){
	if(!this->isactive)
		return;

	//if it is already a parent, clear the children
	if(this->isparent){
		for(unsigned int i=0;i<4;i++){
			delete this->myChildren[i];
			this->myChildren[i]=NULL;
		}
	}

	//divide the node into four parts, each part as a child
	this->myChildren=new QuadNode*[4];
	double xmid = (this->xmin + this->xmax)/2;
	double ymid = (this->ymin + this->ymax)/2;

	this->myChildren[0]= new QuadNode(this->xmin, xmid, ymid, this->ymax);
	this->myChildren[0]->setTheta(this->theta);

	this->myChildren[1]= new QuadNode(xmid, this->xmax, ymid, this->ymax);
	this->myChildren[1]->setTheta(this->theta);

	this->myChildren[2]= new QuadNode(xmid, this->xmax, this->ymin, ymid);
	this->myChildren[2]->setTheta(this->theta);

	this->myChildren[3]= new QuadNode(this->xmin, xmid, this->ymin, ymid);
	this->myChildren[3]->setTheta(this->theta);

	this->isparent=true; 
}

double QuadNode::getXmin(){
	return this->xmin;
}
double QuadNode::getXmax(){
	return this->xmax;
}
double QuadNode::getYmin(){
	return this->ymin;
}
double QuadNode::getYmax(){
	return this->ymax;
}
void QuadNode::setTheta(double inTheta){
	this->theta=inTheta;
	if(!this->isparent)
		return;
	for(unsigned int i=0;i<4;i++)
		this->myChildren[i]->setTheta(this->theta);
}
double QuadNode::getTheta(){
	return this->theta;
}
bool QuadNode::isParent(){
	return this->isparent;
}
