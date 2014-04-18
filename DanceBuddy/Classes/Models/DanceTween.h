//
//  DanceTween.h
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/18/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum DanceTweenCurve {
	DANCE_TWEEN_CURVE_SYNC   = 0,
	DANCE_TWEEN_CURVE_LINEAR = 1,
} DanceTweenCurve_t;



@interface DanceTween : NSObject {
	
}

@property (nonatomic, assign) float fromValue;
@property (nonatomic, assign) float toValue;
@property (nonatomic, assign) float duration;
@property (nonatomic, assign) float progress;
@property (nonatomic, assign) DanceTweenCurve_t curve;

@property (nonatomic, readonly) float tweenDifference;
@property (nonatomic, readonly) float progressRatio;
@property (nonatomic, readonly) float currentValue;

- (id) initWithFrom:(float)from to:(float)to duration:(float)duration curve:(DanceTweenCurve_t)curve;
- (DanceTween*) syncTween;

- (float) processDuration:(float)duration;


@end
