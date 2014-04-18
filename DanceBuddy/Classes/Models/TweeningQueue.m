//
//  TweeningQueue.m
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/18/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import "TweeningQueue.h"

@implementation TweeningQueue

- (id) init {
	if ((self = [super init])) {
		
		_tweens = [NSMutableArray array];
		
	}
	return self;
}

- (void) addTween:(DanceTween*)tween {
	[_tweens addObject:tween];
}

- (float) processDuration:(float)duration {
	
	return _currentValue;
}

@end
