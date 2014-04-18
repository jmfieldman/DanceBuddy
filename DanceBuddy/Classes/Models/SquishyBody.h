//
//  SquishyBody.h
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/17/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SQB_LONGITUDES_COUNT    32
#define SQB_LATITUDE_COUNT      16
#define SQB_TILT_COUNT          32
#define SQB_EXTENSION_COUNT     32

#define SQB_EXTENSION_OFFSET    (SQB_TILT_COUNT * SQB_LATITUDE_COUNT * SQB_LONGITUDES_COUNT)
#define SQB_TILT_OFFSET         (SQB_LATITUDE_COUNT * SQB_LONGITUDES_COUNT)
#define SQB_LATITUDE_OFFSET     (SQB_LONGITUDES_COUNT)

#define SQB_LATITUDE_STRIP_INDEX_COUNT (SQB_LONGITUDES_COUNT * 2 + 2)

@interface SquishyBody : NSObject {
	/* Data for the body */
	OGLVBO_Vertex_Position_Normal_Texture_t vertexes[SQB_LONGITUDES_COUNT * SQB_LATITUDE_COUNT * SQB_TILT_COUNT * SQB_EXTENSION_COUNT];
	
	/* Indices for a latitude strip */
	GLuint latitudeStrip[SQB_LATITUDE_STRIP_INDEX_COUNT];
}


/* The radius of the base of the body (feet) */
@property (nonatomic, assign) GLfloat baseRadius;

/* The radius of the neck of the body */
@property (nonatomic, assign) GLfloat neckRadius;

/* The height of the neck pivot base */
@property (nonatomic, assign) GLfloat pivotHeight;

/* The maximum angle of neck tilt (radians) */
@property (nonatomic, assign) GLfloat maxNeckTilt;

/* The most compressed neck extension length */
@property (nonatomic, assign) GLfloat minNeckExt;

/* The most extended neck extension length */
@property (nonatomic, assign) GLfloat maxNeckExt;

/* The arc length of the body from base to neck */
@property (nonatomic, assign) GLfloat bodyArcLength;


SINGLETON_INTR(SquishyBody);

- (void) renderWithTilt:(float)tilt extenstion:(float)ext;

@end
