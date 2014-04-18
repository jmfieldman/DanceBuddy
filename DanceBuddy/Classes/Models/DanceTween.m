//
//  DanceTween.m
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/18/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import "DanceTween.h"

@implementation DanceTween

- (id) initWithFrom:(float)from to:(float)to duration:(float)duration curve:(DanceTweenCurve_t)curve {
	if ((self = [super init])) {
		_fromValue = from;
		_toValue   = to;
		_duration  = duration;
		_curve     = curve;
		_progress  = 0;
		
		_tweenDifference = _toValue - _fromValue;
	}
	return self;
}

- (DanceTween*) syncTween {
	return [[DanceTween alloc] initWithFrom:0 to:0 duration:0 curve:DANCE_TWEEN_CURVE_SYNC];
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