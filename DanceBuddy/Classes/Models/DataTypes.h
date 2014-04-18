//
//  DataTypes.h
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/17/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef struct OGLVBO_Vertex_Position_Texture {
	GLfloat px;
	GLfloat py;
	GLfloat pz;
	GLfloat nx;
	GLfloat ny;
	GLfloat nz;
	GLfloat s;
	GLfloat t;
} __attribute__((__packed__)) OGLVBO_Vertex_Position_Normal_Texture_t;


