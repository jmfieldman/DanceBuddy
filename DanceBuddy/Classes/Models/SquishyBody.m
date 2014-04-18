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
		_minNeckExt    = 0.5;
		_maxNeckExt    = 0.75;
		_bodyArcLength = 2.5;
		
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

- (double) radiusForAltitude:(double)altitude {
	double alt = altitude * altitude * 3.5;
	alt = pow(altitude, 1.6) * 3;
	if (alt < altitude) alt = altitude;
	return alt;
}

- (void) generateBodyData {
	
	EXLog(OPENGL, DBG, @"Started generateBodyData [%ld verts]", (long)sizeof(vertexes));

			
	for (int tilt = 0; tilt < SQB_TILT_COUNT; tilt++) {
		
		/* How much we're tilting */
		GLfloat tiltRadians = _maxNeckTilt * tilt / (GLfloat)SQB_TILT_COUNT;
		
		/* What is the tilt vector for this tilt? */
		GLfloat_v tiltExtensionVector = { sin(tiltRadians), 0, cos(tiltRadians) };
			
		for (int ext = 0; ext < SQB_EXTENSION_COUNT; ext++) {
			
			/* Create the actual extension vector based on the extension length */
			GLfloat extensionLength = _minNeckExt + (ext / (GLfloat)(SQB_EXTENSION_COUNT-1)) * (_maxNeckExt - _minNeckExt);
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
				
				/* -------- Calculate the bulge -------- */
				
				GLfloat_v neck_v = { neck_x, neck_y, neck_z };
				GLfloat_v base_v = { base_x, base_y, base_z };
				
				/* Need to get the altitude from bisection to point */
				GLfloat_v mid_v;  midpoint_3dv(&base_v, &neck_v, &mid_v);
				GLfloat_v half_v; difference_3dv(&neck_v, &mid_v, &half_v);
				GLfloat   altitude = length_3dv(&half_v);
				
				/* 
				 We know that r * sinT = altitude  ====>  r = altitude / sinT
				 s = rT  ---->  s = altitude * (T / sinT)  -----> altitude / s = sinT / T
				 sinT / T is a taylor series: 1 - T^2 / 6 + T^4 / 120
				 
				 Quadratic (we are given s):
				 
				 T^4 / 120 - T^2 / 6 + (1 - alt/s) = 0
				 
				 T^2 = 1/6 + rt( (1/6)^2 - 4(1-alt/s)(1/120) )  qty / (1/60)
				 
				 T = rt(that^)
				 
				 r = altitude / sinT
				 */
				double perceived_arc_length = (1) * _bodyArcLength / 2;

				double thetasq = 1/6.0 - sqrt( ((1/6.0)*(1/6.0)) - (4 * (1 - altitude/perceived_arc_length) * (1/120.0)) );
				thetasq /= (1/60.0);
				double theta = sqrt(thetasq);
				double radius = altitude / sin(theta);
				
				/* Hacks */
				radius = [self radiusForAltitude:altitude];
				theta  = asin(altitude / radius);
				
				//NSLog(@"%f, %f, %f, %f, %lf, %lf", (float)extensionLength, (float)base_z, (float)neck_z, (float)altitude, theta, radius);
				
				/* We're going to calculate all of this in the XZ plane, then rotate it over the XY plane by longitude radians */
				
				GLfloat_v xz_mapped_neck_v = { neck_v.x * cos(-longitudeRadians) - neck_v.y * sin(-longitudeRadians),
											   neck_v.x * sin(-longitudeRadians) + neck_v.y * cos(-longitudeRadians),
											   neck_v.z };
				
				GLfloat_v xz_mapped_base_v = { _baseRadius, 0, 0 };
				
				/* --- Figure out bisection line --- */
				
				GLfloat_v xz_mapped_midpoint_v = { (xz_mapped_base_v.x + xz_mapped_neck_v.x)/2, 0, (xz_mapped_base_v.z + xz_mapped_neck_v.z)/2 };
				
				/* Angles */
				double angle_base_to_neck = atan2( xz_mapped_neck_v.z - xz_mapped_base_v.z , xz_mapped_neck_v.x - xz_mapped_base_v.x);
				double angle_from_mid_to_center = angle_base_to_neck + M_PI/2;
				double length_from_mid_to_center = radius * cos( theta );
				
				GLfloat_v xz_mapped_circle_center = { xz_mapped_midpoint_v.x + length_from_mid_to_center * cos(angle_from_mid_to_center), 0, xz_mapped_midpoint_v.z + length_from_mid_to_center * sin(angle_from_mid_to_center) };
	
				//NSLog(@"%f, %f, %f, %f, %f", xz_mapped_midpoint_v.x, xz_mapped_midpoint_v.z, xz_mapped_circle_center.x, xz_mapped_circle_center.z, length_from_mid_to_center);
				
				//NSLog(@"%f %f %f", xz_mapped_neck_v.x, xz_mapped_neck_v.y, xz_mapped_neck_v.z );
				
				/* Angles to sweep */
				double current_angle = (angle_from_mid_to_center - M_PI) - theta;
				double next_angle_interval = (2 * theta) / (SQB_LATITUDE_COUNT-1);
								
				for (int latitude = 0; latitude < SQB_LATITUDE_COUNT; latitude++) {
					
					#if 0 /* Sphere test */
					GLfloat xy_radian = M_PI * 2 * longitude / (GLfloat)SQB_LONGITUDES_COUNT;
					GLfloat x_comp = cos(xy_radian);
					GLfloat y_comp = sin(xy_radian);
					
					GLfloat z_radian = ( - M_PI / 4 ) + (M_PI / 2) * latitude / (GLfloat)SQB_LATITUDE_COUNT;
					GLfloat z_comp = sin(z_radian);
					
					normalize_3d_to_length(&x_comp, &y_comp, &z_comp, 1);
					#endif
					
					#if 0 /* Linear test */
					GLfloat lat_scale = latitude / (GLfloat)(SQB_LATITUDE_COUNT-1);
					
					GLfloat x_comp = base_x * lat_scale + neck_x * (1 - lat_scale);
					GLfloat y_comp = base_y * lat_scale + neck_y * (1 - lat_scale);
					GLfloat z_comp = base_z * lat_scale + neck_z * (1 - lat_scale);
					#endif
										
					GLfloat_v xz_circle_v = { radius * cos(current_angle), 0, radius * sin(current_angle) };
					GLfloat_v xz_mapped_point_v = { xz_mapped_circle_center.x + xz_circle_v.x, 0, xz_mapped_circle_center.z + xz_circle_v.z};
					current_angle += next_angle_interval;
					
					GLfloat_v unmapped_point_v = { xz_mapped_point_v.x * cos(longitudeRadians) - xz_mapped_point_v.y * sin(longitudeRadians),
												   xz_mapped_point_v.x * sin(longitudeRadians) + xz_mapped_point_v.y * cos(longitudeRadians),
												   xz_mapped_point_v.z };
										
					OGLVBO_Vertex_Position_Normal_Texture_t *vertex = &vertexes[ext * SQB_EXTENSION_OFFSET +
																				tilt * SQB_TILT_OFFSET +
																				latitude * SQB_LATITUDE_OFFSET +
																				longitude];

					
					vertex->px = unmapped_point_v.x;
					vertex->py = unmapped_point_v.y;
					vertex->pz = unmapped_point_v.z;
					
					unmapped_point_v.x = xz_circle_v.x * cos(longitudeRadians);
					unmapped_point_v.y = xz_circle_v.x * sin(longitudeRadians);
					unmapped_point_v.z = xz_circle_v.z;
					normalize_3dv_to_length(&unmapped_point_v, 1);
					vertex->nx = unmapped_point_v.x;
					vertex->ny = unmapped_point_v.y;
					vertex->nz = unmapped_point_v.z;
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
