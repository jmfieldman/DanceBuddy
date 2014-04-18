//
//  SquishyBody.m
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/17/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import "SquishyBody.h"

@implementation SquishyBody

SINGLETON_IMPL(SquishyBody);

- (id) init {
	if ((self = [super init])) {

		_baseRadius    = 1.0;
		_neckRadius    = 1.0;
		_pivotHeight   = 0.5;
		_maxNeckTilt   = 20 * M_PI / 180.0;
		_minNeckExt    = 0.25;
		_maxNeckExt    = 0.75;
		_bodyArcLength = 2;
		
		[self generateBodyData];
		
	}
	return self;
}


/* The body is created with the follow dimensions:
 
 * Base is a ring on the XY plane at Z=0; radius _baseRadius
 * From 0,0,0, the pivot base is extended _pivotHeight into +Z
 * The "neck ring" then tilts towards the +X axis and extended by "ext" amount (min to max)
 * For each longitude, the latitude values are calculated by making a circle segment w/ length _bodyArcLength between neck and base

 */

- (void) generateBodyData {
	
	EXLog(OPENGL, DBG, @"Started generateBodyData [%ld verts]", (long)sizeof(vertexes));

	GLfloat_v pivotHead = { 0, 0, _pivotHeight };
	
		
	for (int tilt = 0; tilt < SQB_TILT_COUNT; tilt++) {
		
		
		
		for (int ext = 0; ext < SQB_EXTENSION_COUNT; ext++) {
			for (int latitude = 0; latitude < SQB_LATITUDE_COUNT; latitude++) {
				for (int longitude = 0; longitude < SQB_LONGITUDES_COUNT; longitude++) {
					
					GLfloat xy_radian = M_PI * 2 * longitude / (GLfloat)SQB_LONGITUDES_COUNT;
					GLfloat x_comp = cos(xy_radian);
					GLfloat y_comp = sin(xy_radian);
					
					GLfloat z_radian = ( - M_PI / 4 ) + (M_PI / 2) * latitude / (GLfloat)SQB_LATITUDE_COUNT;
					GLfloat z_comp = sin(z_radian);
					
					normalize_3d_to_length(&x_comp, &y_comp, &z_comp, 1);
					
					OGLVBO_Vertex_Position_Normal_Texture_t *vertex = &vertexes[ext * SQB_EXTENTION_OFFSET +
																				tilt * SQB_TILE_OFFSET +
																				latitude * SQB_LATITUDE_OFFSET +
																				longitude];
					vertex->px = x_comp;
					vertex->py = y_comp;
					vertex->pz = z_comp;
					
					vertex->nx = x_comp;
					vertex->ny = y_comp;
					vertex->nz = z_comp;
				}
			}
		}
	}
	
	int longitude;
	for (longitude = 0; longitude < (SQB_LATITUDE_STRIP_INDEX_COUNT/2-1); longitude ++) {
		latitudeStrip[longitude*2]   = longitude;
		latitudeStrip[longitude*2+1] = longitude + SQB_LATITUDE_OFFSET;
	}
	latitudeStrip[SQB_LATITUDE_STRIP_INDEX_COUNT-2] = 0;
	latitudeStrip[SQB_LATITUDE_STRIP_INDEX_COUNT-1] = SQB_LATITUDE_OFFSET;
	
	EXLog(OPENGL, DBG, @"Finished generateBodyData");
}

- (void) renderInGL {

	static double s = 0;
	if (s == 0) s = CFAbsoluteTimeGetCurrent();
	double t = CFAbsoluteTimeGetCurrent();
	double dif = t - s;
	
	/* White */
	glColor4f(1, 1, 1, 1);
	
	/* Release any held buffer */
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	/* Client state */
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_NORMAL_ARRAY);
	
	/* Lighting */
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	
	glPushMatrix();
	
	glTranslatef(0, 0, 3);
	glRotatef(dif * 30, 1, 0, 0);
	
	for (int latitude = 0; latitude < (SQB_LATITUDE_COUNT-1); latitude++) {
		/* Set pointers */
		glVertexPointer(3, GL_FLOAT, sizeof(OGLVBO_Vertex_Position_Normal_Texture_t), &vertexes[latitude * SQB_LATITUDE_OFFSET].px);
		glNormalPointer(   GL_FLOAT, sizeof(OGLVBO_Vertex_Position_Normal_Texture_t), &vertexes[latitude * SQB_LATITUDE_OFFSET].nx);
		
		glDrawElements(GL_TRIANGLE_STRIP, SQB_LATITUDE_STRIP_INDEX_COUNT, GL_UNSIGNED_INT, latitudeStrip);
	}
	
	
	glPopMatrix();
	
}


@end
