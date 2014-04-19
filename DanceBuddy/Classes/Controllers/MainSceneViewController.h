//
//  MainSceneViewController.h
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/17/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DanceSceneView.h"
#import "SquishyBody.h"

@interface MainSceneViewController : UIViewController <MPMediaPickerControllerDelegate> {
	/* Animation Timer */
	CADisplayLink  *_displayLink;
	double          _lastSliceTimestamp;
	
	/* Scene */
	DanceSceneView *_scene;
	
	/* Dancer */
	SquishyBody *_dancer;
}

SINGLETON_INTR(MainSceneViewController);

@end
