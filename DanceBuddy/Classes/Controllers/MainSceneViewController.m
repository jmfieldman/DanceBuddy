//
//  MainSceneViewController.m
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/17/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import "MainSceneViewController.h"


@interface MainSceneViewController ()

@end

@implementation MainSceneViewController

SINGLETON_IMPL(MainSceneViewController);

- (id)init {
	if ((self = [super init])) {
		self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
		self.view.backgroundColor = [UIColor redColor];
		
		_scene = [[DanceSceneView alloc] initWithFrame:self.view.bounds];
		_scene.antiAliasingConfig = YES;
		[self.view addSubview:_scene];
		
		_dancer = [[SquishyBody alloc] init];
		[_scene.dancers addObject:_dancer];
		
		/* Begin animations */
		_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(processTimeslice:)];
		[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		
		/* Init timeslice */
		_lastSliceTimestamp = CFAbsoluteTimeGetCurrent();
		
						
		UITapGestureRecognizer *gest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
		[_scene addGestureRecognizer:gest];
	}
	return self;
}

- (void) tapped:(UIGestureRecognizer*)g {
	MPMediaPickerController *pickerController =	[[MPMediaPickerController alloc]
												 initWithMediaTypes: MPMediaTypeMusic];
	pickerController.prompt = @"Choose song to export";
	pickerController.allowsPickingMultipleItems = NO;
	pickerController.delegate = self;
	[self presentViewController:pickerController animated:YES completion:nil];
}

- (void) processTimeslice:(id)sender {
	double currentSliceTimestamp = CFAbsoluteTimeGetCurrent();
	double timeDiff = currentSliceTimestamp - _lastSliceTimestamp; /* Used to get time diff between frames */
	_lastSliceTimestamp = currentSliceTimestamp;
	
	[self _frameRateCheckpoint];
	
	[_dancer processDuration:timeDiff];
	[_scene render];
}

- (void) _frameRateCheckpoint {
	static int frames = 0;
	static int lasttime = 0;
	int curtime = time(0);
	frames++;
	
	if (curtime > lasttime) {
		EXLog(RENDER, INFO, @"{%d fps}", frames);
		frames = 0;
		lasttime = curtime;
	}
}

#pragma mark MPMediaPickerControllerDelegate

- (void)mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
	[self dismissViewControllerAnimated:YES completion:nil];
	if ([mediaItemCollection count] < 1) {
		return;
	}
	
	MPMediaItem *song = [[mediaItemCollection items] objectAtIndex:0];
	static AudioAnalyzer *a = nil;
	if (!a) a = [[AudioAnalyzer alloc] init];
	[a convertSong:song];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
