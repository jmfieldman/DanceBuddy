//
//  DanceSceneView.m
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/17/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import "DanceSceneView.h"
#import "SquishyBody.h"

static float s_tilt = 0;
static float s_ext  = 0;

@implementation DanceSceneView

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
	
		/* Initialize the layer and context */
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		/* Initialize GL layer properties */
		eaglLayer.contentsScale = [UIScreen mainScreen].scale;
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
		/* Create OpenGL 1.1 context */
		_GLcontext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
		/* Make sure everything worked during layer/context init */
		if (!_GLcontext || ![EAGLContext setCurrentContext:_GLcontext]) {
			EXLog(OPENGL, ERR, @"There was an error creating the openGL context");
			return nil;
		}
		
		if (![self createBuffers]) {
			EXLog(OPENGL, ERR, @"There was an error creating the openGL buffers");
			return nil;
		}
		
		/* Setup viewport */
		glViewport(0, 0, _viewBackingPixelWidth, _viewBackingPixelHeight);
		
		/* Setup up projection matrix */
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		
		#define DEGREES_TO_RADIANS(z) (( z / 180.0 ) * 3.141592653589793)
		const GLfloat zNear = 0.01, zFar = 100.0, fieldOfView = 45;
		GLfloat size = zNear * tanf(DEGREES_TO_RADIANS(fieldOfView) / 2.0);
		CGRect rect = self.bounds;
		glFrustumf(-size, size, -size / (rect.size.width / rect.size.height), size /
				   (rect.size.width / rect.size.height), zNear, zFar);
		
		glDepthRangef(zNear, zFar);
		
		/* Leave projection mode */
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();		
		
		UIPanGestureRecognizer *gest = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGest:)];
		[self addGestureRecognizer:gest];
	}
	return self;
}

- (void) panGest:(UIPanGestureRecognizer*)gest {
	CGPoint movement = [gest translationInView:self];
	[gest setTranslation:CGPointZero inView:self];
	
	s_tilt += movement.x / 100;
	s_ext  -= movement.y / 100;
	
	if (s_tilt < 0) s_tilt = 0; if (s_tilt > 1) s_tilt = 1;
	if (s_ext < 0) s_ext = 0; if (s_ext > 1) s_ext = 1;
}

/* Anti-alias config */
+ (void) setAntiAliasingConfig:(BOOL)antiAliasOn {
	[[NSUserDefaults standardUserDefaults] setBool:antiAliasOn forKey:@"antialias"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL) antiAliasingConfig {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"antialias"];
}


/* Override layer type for openGL layer */
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void) render {
	/* Enable AA if necessary */
	if (_antiAliasEnabled) {
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, _msaaFrameBuffer);
	}
	
	/* Clear */
	glClearColor(0,1,0,0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	/* Initialize matrix mode */
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	/* Need Z inversion, since deep should be positive */
	glScalef(1, 1, -1);
	
	/* Setup depth testing.. walls and planes use painters sorted structures, so don't need to actually test depth (but leave mask on) */
	glDepthFunc(GL_LEQUAL);
	glEnable(GL_DEPTH_TEST);
	glDepthMask(GL_TRUE);
	
	
	/* ------- Drawing -------- */
	
	[[SquishyBody sharedInstance] renderWithTilt:s_tilt extenstion:s_ext];
	
	/* ------------------------ */
	
	/* Resolve AA */
	if (_antiAliasEnabled) {
		GLenum attachments[] = {GL_DEPTH_ATTACHMENT_OES};
		glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);
		
		glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, _msaaFrameBuffer);
		glBindFramebufferOES(GL_DRAW_FRAMEBUFFER_APPLE, _stdFrameBuffer);
		
		/* Call a resolve to combine both buffers */
		glResolveMultisampleFramebufferAPPLE();
	}
	
	/* Finally: Swap buffers */
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _stdRenderBuffer);
	[_GLcontext presentRenderbuffer:GL_RENDERBUFFER_OES];
}

/*----------------------------------------------------------------------------------- */

#pragma mark Buffer Utility Functions

- (BOOL) createBuffers {
	
	/* Create buffers */
	glGenFramebuffersOES(1, &_stdFrameBuffer);
	glGenRenderbuffersOES(1, &_stdRenderBuffer);
	
	/* Bind them as the active opengl handles */
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _stdFrameBuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _stdRenderBuffer);
	[_GLcontext renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _stdRenderBuffer);
	
	/* Get dimension metrics */
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &_viewBackingPixelWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &_viewBackingPixelHeight);
	
	EXLog(OPENGL, INFO, @"createBuffers: renderbuffer dimensions (%f, %f)", (float)_viewBackingPixelWidth, (float)_viewBackingPixelHeight);
	
	/* Check framebuffer */
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		EXLog(OPENGL, ERR, @"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	/* Create depth buffer */
	{
		glGenRenderbuffersOES(1, &_stdDepthBuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, _stdDepthBuffer);
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, _viewBackingPixelWidth, _viewBackingPixelHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _stdDepthBuffer);
		
		/* Setup initial depth features */
		glDepthFunc(GL_LEQUAL);
		glDisable(GL_DEPTH_TEST);
		glDepthMask(GL_TRUE);
    }
	
	/* For antialiasing */
	_antiAliasEnabled = [DanceSceneView antiAliasingConfig];
	if (_antiAliasEnabled) {
		
		/* Generate our MSAA Frame and Render buffers */
		glGenFramebuffersOES(1, &_msaaFrameBuffer);
		glGenRenderbuffersOES(1, &_msaaRenderBuffer);
		
		/* Bind our MSAA buffers */
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, _msaaFrameBuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, _msaaRenderBuffer);
		
		/* Generate the msaaDepthBuffer. */
		/* 4 will be the number of pixels that the MSAA buffer will use in order to make one pixel on the render buffer. */
		glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_RGB5_A1_OES, _viewBackingPixelWidth, _viewBackingPixelHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, _msaaRenderBuffer);
		glGenRenderbuffersOES(1, &_msaaDepthBuffer);
		
		/* Bind the msaa depth buffer. */
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, _msaaDepthBuffer);
		glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_DEPTH_COMPONENT16_OES, _viewBackingPixelWidth , _viewBackingPixelHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _msaaDepthBuffer);
		
	}
	
	[EAGLContext setCurrentContext:_GLcontext];
	
	/* Choose frame buffer based on AA */
	if (_antiAliasEnabled) {
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, _msaaFrameBuffer);
	} else {
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, _stdFrameBuffer);
	}
	
	return YES;
}

- (void) destroyBuffers {
	if (_stdFrameBuffer)  glDeleteFramebuffersOES(1,  &_stdFrameBuffer);  _stdFrameBuffer  = 0;
	if (_stdRenderBuffer) glDeleteRenderbuffersOES(1, &_stdRenderBuffer); _stdRenderBuffer = 0;
	if (_stdDepthBuffer)  glDeleteRenderbuffersOES(1, &_stdDepthBuffer);  _stdDepthBuffer  = 0;
	
	if (_antiAliasEnabled) {
		if (_msaaFrameBuffer)  glDeleteFramebuffersOES(1,  &_msaaFrameBuffer);  _msaaFrameBuffer  = 0;
		if (_msaaRenderBuffer) glDeleteRenderbuffersOES(1, &_msaaRenderBuffer); _msaaRenderBuffer = 0;
		if (_msaaDepthBuffer)  glDeleteRenderbuffersOES(1, &_msaaDepthBuffer);  _msaaDepthBuffer  = 0;
	}
}




@end
