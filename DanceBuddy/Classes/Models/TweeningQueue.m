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
	
	/* No tweens?  Do nothing */
	if (![_tweens count]) return _currentValue;
	
	/* Keep processing the first tween until we're done */
	while (YES) {
		DanceTween *next = _tweens[0];
		duration = [next processDuration:duration];
		
		/* We're done processing if duration is 0 */
		if (duration == 0) {
			
			/* Update the value if this isn't a sync tween */
			if (next.curve != DANCE_TWEEN_CURVE_SYNC) {
				_currentValue = next.currentValue;

				/* Call the completion block */
				if (next.completionBlock) {
					next.completionBlock(next);
				}
			}
			
			break;
		}

		/* Otherwise we finished the existing tween and have more time left */
		[_tweens removeObjectAtIndex:0];
		
		/* In case we have none left.. just return with the last seen value */
		if (![_tweens count]) {
			_currentValue = next.currentValue;
			return _currentValue;
		}
		
		/* Otherwise the loop continues.. */
	}
	
	return _currentValue;
}

@end
