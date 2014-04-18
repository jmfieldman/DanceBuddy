//
//  DanceTween.m
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/18/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import "DanceTween.h"

@implementation DanceTween

- (id) initWithDuration:(float)duration toValue:(float)toValue curve:(DanceTweenCurve_t)curve completion:(DanceTweenCompletionBlock)block {
	if ((self = [super init])) {
		_toValue   = toValue;
		_duration  = duration;
		_curve     = curve;
		_progress  = 0;
		
		self.completionBlock = block;
				
	}
	return self;
}

+ (DanceTween*) syncTween {
	return [[DanceTween alloc] initWithDuration:0 toValue:0 curve:DANCE_TWEEN_CURVE_SYNC completion:nil];
}

+ (DanceTween*) syncTweenWithCompletion:(DanceTweenCompletionBlock)block {
	DanceTween *tween = [DanceTween syncTween];
	tween.completionBlock = block;
	return tween;
}

- (void) setFromValue:(float)fromValue {
	_fromValue = fromValue;
	_tweenDifference = _toValue - _fromValue;
}

- (float) processDuration:(float)duration {
	
	if (_curve == DANCE_TWEEN_CURVE_SYNC) {
		/* Sync tweens absorb progress, waiting to be released */
		_progress += duration;
		return 0;
	}
	
	/* Increase progess; return overage if we're done */
	_progress += duration;
	if (_progress >= _duration) {
		_progressRatio = 1;
		_currentValue = _toValue;
		return (_progress - _duration);
	}
	
	/* Update progress ratio */
	_progressRatio = _progress / _duration;
	
	/* Adjust value based on curve */
	switch (_curve) {
		case DANCE_TWEEN_CURVE_LINEAR:
			_currentValue = _fromValue + (_tweenDifference * _progressRatio);
			break;
			
		default:
			break;
	}
	
	return 0;
}

@end
