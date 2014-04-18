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

@class DanceTween;
typedef void (^DanceTweenCompletionBlock)(DanceTween* tween);


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

@property (nonatomic, copy) DanceTweenCompletionBlock completionBlock;

- (id) initWithDuration:(float)duration toValue:(float)toValue curve:(DanceTweenCurve_t)curve completion:(DanceTweenCompletionBlock)block;

+ (DanceTween*) syncTween;
+ (DanceTween*) syncTweenWithCompletion:(DanceTweenCompletionBlock)block;

/* Returns the remaining time after duration has been processed by this tween (0 if this absorbed it all) */
- (float) processDuration:(float)duration;


@end
