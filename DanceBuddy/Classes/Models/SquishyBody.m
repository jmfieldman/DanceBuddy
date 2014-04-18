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
		_pivotHeight   = 0.75;
		_maxNeckTilt   = 20 * M_PI / 180.0;
		_minNeckExt    = 0.25;
		_maxNeckExt    = 2.75;
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

			
	for (int tilt = 0; tilt < SQB_TILT_COUNT; tilt++) {
		
		/* How much we're tilting */
		GLfloat tiltRadians = _maxNeckTilt * tilt / (GLfloat)SQB_TILT_COUNT;
		
		/* What is the tilt vector for this tilt? */
		GLfloat_v tiltExtensionVector = { sin(tiltRadians), 0, cos(tiltRadians) };
			
		for (int ext = 0; ext < SQB_EXTENSION_COUNT; ext++) {
			
			/* Create the actual extension vector based on the extension length */
			GLfloat extensionLength = _minNeckExt + (ext / (GLfloat)SQB_EXTENSION_COUNT) * (_maxNeckExt - _minNeckExt);
			GLfloat_v trueExtensionVector = { tiltExtensionVector.x * extensionLength, 0, tiltExtensionVector.z * extensionLength };
			
			for (int longitude = 0; longitude < SQB_LONGITUDES_COUNT; longitude++) {
				
				GLfloat longitudeRadians = M_PI * 2 * longitude / (GLfloat)SQB_LONGITUDES_COUNT;
				
				/* What is the tilted neck vector for this longitude? */
				
				/* Start with the neck ring centered at the pivot height */
				GLfloat neck_x = cos(longitudeRadians) * _neckRadius;
				GLfloat neck_y = sin(longitudeRadians) * _neckRadius;
				GLfloat neck_z = _pivotHeight;

				/* As we rotate tilt-theta down towards +X, the only values that change are x and z coords. */
				neck_z = neck_z + sin(-tiltRadians) * neck_x; /* Radius of our circle is neck_x */
				neck_x = neck_x * cos(-tiltRadians);
				
				/* Now we add the extension vector */
				neck_x += trueExtensionVector.x;
				neck_y += trueExtensionVector.y;
				neck_z += trueExtensionVector.z;
				
				/* Let's also get the base vector; this is easier */
				GLfloat base_x = cos(longitudeRadians) * _baseRadius;
				GLfloat base_y = sin(longitudeRadians) * _baseRadius;
				GLfloat base_z = 0;
				
				for (int latitude = 0; latitude < SQB_LATITUDE_COUNT; latitude++) {
					
					#if 0 /* Sphere test */
					GLfloat xy_radian = M_PI * 2 * longitude / (GLfloat)SQB_LONGITUDES_COUNT;
					GLfloat x_comp = cos(xy_radian);
					GLfloat y_comp = sin(xy_radian);
					
					GLfloat z_radian = ( - M_PI / 4 ) + (M_PI / 2) * latitude / (GLfloat)SQB_LATITUDE_COUNT;
					GLfloat z_comp = sin(z_radian);
					
					normalize_3d_to_length(&x_comp, &y_comp, &z_comp, 1);
					#endif
					
					GLfloat lat_scale = latitude / (GLfloat)(SQB_LATITUDE_COUNT-1);
					
					GLfloat x_comp = base_x * lat_scale + neck_x * (1 - lat_scale);
					GLfloat y_comp = base_y * lat_scale + neck_y * (1 - lat_scale);
					GLfloat z_comp = base_z * lat_scale + neck_z * (1 - lat_scale);
					
					
					
					OGLVBO_Vertex_Position_Normal_Texture_t *vertex = &vertexes[ext * SQB_EXTENSION_OFFSET +
																				tilt * SQB_TILT_OFFSET +
																				latitude * SQB_LATITUDE_OFFSET +
																				longitude];
					vertex->px = x_comp;
					vertex->py = y_comp;
					vertex->pz = z_comp;
					
					normalize_3d_to_length(&x_comp, &y_comp, &z_comp, 1);
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

- (void) renderWithTilt:(float)tilt extenstion:(float)ext {

	static double s = 0;
	if (s == 0) s = CFAbsoluteTimeGetCurrent();
	double t = CFAbsoluteTimeGetCurrent();
	//double dif = t - s;
	
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
	
	glTranslatef(0, -2, 5);
	//glRotatef(dif * 60, 1, 0, 0);
	glRotatef(-90, 1, 0, 0);
	
	int tilti = (int)(31 * tilt);
	int exti  = (int)(31 * ext);
	
	int tiltOffset = tilti * SQB_TILT_OFFSET;
	int extOffset  = exti  * SQB_EXTENSION_OFFSET;
	
	for (int latitude = 0; latitude < (SQB_LATITUDE_COUNT-1); latitude++) {
		/* Set pointers */
		glVertexPointer(3, GL_FLOAT, sizeof(OGLVBO_Vertex_Position_Normal_Texture_t), &vertexes[latitude * SQB_LATITUDE_OFFSET + tiltOffset + extOffset].px);
		glNormalPointer(   GL_FLOAT, sizeof(OGLVBO_Vertex_Position_Normal_Texture_t), &vertexes[latitude * SQB_LATITUDE_OFFSET + tiltOffset + extOffset].nx);
		
		glDrawElements(GL_TRIANGLE_STRIP, SQB_LATITUDE_STRIP_INDEX_COUNT, GL_UNSIGNED_INT, latitudeStrip);
	}
	
	
	glPopMatrix();
	
}


@end
