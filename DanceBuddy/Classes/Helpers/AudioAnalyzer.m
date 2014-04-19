//
//  AudioAnalyzer.m
//  DanceBuddy
//
//  Created by Jason Fieldman on 4/18/14.
//  Copyright (c) 2014 Jason Fieldman. All rights reserved.
//

#import "AudioAnalyzer.h"


@implementation AudioAnalyzer

- (void) analyzePCM:(NSString*)path {
	
	/* Test */
	//NSString *path = [[NSBundle mainBundle] pathForResource:@"addicted" ofType:@"wav"];
	
	NSData *data = [NSData dataWithContentsOfFile:path];
	
	static __strong AVAudioPlayer *player = nil;
	player = [[AVAudioPlayer alloc] initWithData:data error:NULL];
	
	player.volume = 1.0;    // optional to play music
	
	[player prepareToPlay]; // optional to play music
	//[player play];          // optional to play music
	
	const char *source_path = [path UTF8String];
	int samplerate = [[player.settings valueForKey:@"AVSampleRateKey"] longValue];
	int win_size = 1024;
	int hop_size = 256;
	uint_t n_frames = 0, read = 0;
	
	aubio_source_t * source = new_aubio_source((char*)source_path, samplerate, hop_size);
	
	fvec_t * in = new_fvec (hop_size); // input audio buffer
	fvec_t * out = new_fvec (2); // output position
	// create tempo object
	aubio_tempo_t * o = new_aubio_tempo("default", win_size, hop_size, samplerate);
	
	//aubio_tempo_set_threshold(o, 50.9);
	
	do {
		// put some fresh data in input vector
		aubio_source_do(source, in, &read);
		// execute tempo
		aubio_tempo_do(o,in,out);
		// do something with the beats
		if (out->data[0] != 0) {
			printf("beat at %.3fms, %.3fs, frame %d, %.2fbpm with confidence %.2f [%f]\n",
				   aubio_tempo_get_last_ms(o), aubio_tempo_get_last_s(o),
				   aubio_tempo_get_last(o), aubio_tempo_get_bpm(o), aubio_tempo_get_confidence(o), (float)out->data[0]);
		}
		n_frames += read;
	} while ( read == hop_size );

	printf("read %.2fs, %d frames at %dHz (%d blocks) from %s\n",
			  n_frames * 1. / samplerate,
			  n_frames, samplerate,
			  n_frames / hop_size, source_path);
	// clean up memory
	del_aubio_tempo(o);
	del_fvec(in);
	del_fvec(out);
	del_aubio_source(source);
	
}


-(void) convertSong:(MPMediaItem*)song {
	// set up an AVAssetReader to read from the iPod Library
	NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
	if (!assetURL) {
		NSLog(@"NO URL");
		return;
	}
	AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
	
	NSError *assetError = nil;
	AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&assetError];
	if (assetError) {
		NSLog (@"error: %@", assetError);
		return;
	}
	
	AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks audioSettings: nil];
	if (![assetReader canAddOutput: assetReaderOutput]) {
		NSLog (@"can't add reader output... die!");
		return;
	}
	[assetReader addOutput: assetReaderOutput];
	
	NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
	NSString *exportPath = [documentsDirectoryPath stringByAppendingPathComponent:@"exported.caf"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
		[[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
	}
	NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
	AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:exportURL fileType:AVFileTypeCoreAudioFormat error:&assetError];
	if (assetError) {
		NSLog (@"error: %@", assetError);
		return;
	}
	
	AudioChannelLayout channelLayout;
	memset(&channelLayout, 0, sizeof(AudioChannelLayout));
	channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
	NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
									[NSNumber numberWithFloat:44100.0], AVSampleRateKey,
									[NSNumber numberWithInt:2], AVNumberOfChannelsKey,
									[NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
									[NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
									[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
									[NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
									[NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
									nil];
	AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:outputSettings];
	if ([assetWriter canAddInput:assetWriterInput]) {
		[assetWriter addInput:assetWriterInput];
	} else {
		NSLog (@"can't add asset writer input... die!");
		return;
	}
	
	assetWriterInput.expectsMediaDataInRealTime = NO;
	
	[assetWriter startWriting];
	[assetReader startReading];
	
	AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
	CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
	[assetWriter startSessionAtSourceTime: startTime];
	
	__block UInt64 convertedByteCount = 0;
	
	dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
	[assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue
											usingBlock: ^
	 {
		 // NSLog (@"top of block");
		 while (assetWriterInput.readyForMoreMediaData) {
			 CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
			 if (nextBuffer) {
				 // append buffer
				 [assetWriterInput appendSampleBuffer: nextBuffer];
				 //				NSLog (@"appended a buffer (%d bytes)",
				 //					   CMSampleBufferGetTotalSampleSize (nextBuffer));
				 convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
				 // oops, no
				 // sizeLabel.text = [NSString stringWithFormat: @"%ld bytes converted", convertedByteCount];
				 
				 #if 0
				 NSNumber *convertedByteCountNumber = [NSNumber numberWithLong:(long)convertedByteCount];
				 				 
				 [self performSelectorOnMainThread:@selector(updateSizeLabel:)
										withObject:convertedByteCountNumber
									 waitUntilDone:NO];
				 #endif
			 } else {
				 // done!
				 [assetWriterInput markAsFinished];
				 [assetWriter finishWritingWithCompletionHandler:^{
					 NSLog(@"finishedWritingWithCompletionHandler");
					 [self analyzePCM:exportPath];
				 }];
				 [assetReader cancelReading];
				 NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]
													   attributesOfItemAtPath:exportPath
													   error:nil];
				 NSLog (@"done. file size is %ld", (long)[outputFileAttributes fileSize]);
				 #if 0
				 NSNumber *doneFileSize = [NSNumber numberWithLong:(long)[outputFileAttributes fileSize]];
				 [self performSelectorOnMainThread:@selector(updateCompletedSizeLabel:)
										withObject:doneFileSize
									 waitUntilDone:NO];
				 #endif
				 // release a lot of stuff
				 break;
			 }
		 }
		 
	 }];
	NSLog (@"bottom of convertTapped:");
}



@end
