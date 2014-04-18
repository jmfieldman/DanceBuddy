//
//  TweeningQueue.h
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/18/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DanceTween.h"

@interface TweeningQueue : NSObject {
	NSMutableArray *_tweens;
}

@property (nonatomic, readonly) float currentValue;
@property (nonatomic, readonly) BOOL  synchronizingTime;

- (void) addTween:(DanceTween*)tween;
- (void) popTween;

/* Returns the current value after the duration is processed */
- (float) processDuration:(float)duration;

@end
