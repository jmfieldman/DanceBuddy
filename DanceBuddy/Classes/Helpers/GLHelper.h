//
//  GLHelper.h
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/17/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataTypes.h"

/* Normalize vector to length */
__attribute__((unused)) static void normalize_3d_to_length(GLfloat *x, GLfloat *y, GLfloat *z, GLfloat length) {
	GLfloat cur_len = sqrt((*x) * (*x) + (*y) * (*y) + (*z) * (*z));
	if (cur_len == 0) return;
	GLfloat grow_ratio = length / cur_len;
	*x *= grow_ratio;
	*y *= grow_ratio;
	*z *= grow_ratio;
}

__attribute__((unused)) static void normalize_3dv_to_length(GLfloat_v *v, GLfloat length) {
	GLfloat cur_len = sqrt((v->x) * (v->x) + (v->y) * (v->y) + (v->z) * (v->z));
	if (cur_len == 0) return;
	GLfloat grow_ratio = length / cur_len;
	v->x *= grow_ratio;
	v->y *= grow_ratio;
	v->z *= grow_ratio;
}