//
//  AudioAnalyzer.h
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/18/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <aubio/aubio.h>

@interface AudioAnalyzer : NSObject

- (void) analyzePCM:(NSString*)path;
-(void) convertSong:(MPMediaItem*)song;

@end
