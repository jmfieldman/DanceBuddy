//
//  MainSceneViewController.h
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/17/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DanceSceneView.h"

@interface MainSceneViewController : UIViewController {
	/* Animation Timer */
	CADisplayLink  *_displayLink;
	double          _lastSliceTimestamp;
	
	/* Scene */
	DanceSceneView *_scene;
}

SINGLETON_INTR(MainSceneViewController);

@end
