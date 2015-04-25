#ifndef QUADNODE_H
#define QUADNODE_H

#include "Body.h"


#include <string> 


class Body;

class QuadNode{
public:
	double xmin,xmax;
	double ymin,ymax;
	double theta;
	double mx, my;//center of mass
	double m; //total mass
	bool isactive; 
	bool isparent;
	Body* me;
	QuadNode** myChildren;  //Not sure 

	//Create a quadtree with a certain space
	QuadNode(double x1, double x2, 
		double y1, double y2);

    //Create a quadtree using existing file
//	QuadNode( BodySystem* bs );

    // deletes all associated memory
	~QuadNode();
    
    //Add a single body to the quadnode
	void addBody (Body* body);

    //Add all bodies in the existing file to the quadnode
//	void addAllBody (BodySystem* bs);

	//Clear the contents of the node
	void clearNode ();

	//Recalculate center of mass and total mass
	void calcMass();

	//Calculate a single body's force
	void calcForce(Body* body);

	//Calculate all force
//	void calcAllForce(BodySystem* bs);

	//Get which quadrant the body is in 
	unsigned int getQuadrant(Body* body);

	//Get the left side of the quadnode
	double getXmin();

    //Get the right side of the quadnode
	double getXmax();
    
    //Get the botton of the quadnode
	double getYmin();

	//Get the top of the quadnode
	double getYmax();

	//Set the threshold of distance/r
	void setTheta(double inTheta);

	//get the value of threshold theta
	double getTheta();

	//If the quadnode is a parent, return true
	bool isParent();

private:
    //create children for this node
	void createChildren();

};



#endif

