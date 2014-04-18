//
//  DanceSceneView.h
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/17/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DanceSceneView : UIView {
	/* EAGL context */
	EAGLContext *_GLcontext;	
	
	/* Normal render buffers */
	GLuint _stdRenderBuffer;
	GLuint _stdFrameBuffer;
	GLuint _stdDepthBuffer;
	
	/* Anti-aliasing */
	BOOL   _antiAliasEnabled;
	GLuint _msaaFrameBuffer;
	GLuint _msaaRenderBuffer;
	GLuint _msaaDepthBuffer;
	
	/* View dimensions */
	GLint  _viewBackingPixelWidth;
	GLint  _viewBackingPixelHeight;
	
	
}

@property (nonatomic, assign) BOOL antiAliasingConfig;

- (void) render;

@end
