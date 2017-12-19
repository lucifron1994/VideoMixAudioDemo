//
//  WBVideoMixAudioEngine.h
//  VideoMixAudioDemo
//
//  Created by lucifron on 2017/12/18.
//  Copyright © 2017年 lucifron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface WBVideoMixAudioEngine : NSObject

@property (nonatomic, strong) AVURLAsset *videoAsset;
@property (nonatomic, strong) AVURLAsset *musicAsset;
@property (nonatomic, assign) CMTimeRange videoTimeRange;

- (void)buildCompositionObjectsForPlayback;
- (AVPlayerItem *)playerItem;

- (void)setVideoVolume:(CGFloat)volume;
- (void)setMusicVolume:(CGFloat)volume;

- (void)exportAtPath:(NSString *)outputPath completion:(void (^)(BOOL success))completion;

@end
