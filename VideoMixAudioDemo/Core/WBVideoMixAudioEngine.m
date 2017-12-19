//
//  WBVideoMixAudioEngine.m
//  VideoMixAudioDemo
//
//  Created by lucifron on 2017/12/18.
//  Copyright © 2017年 lucifron. All rights reserved.
//

#import "WBVideoMixAudioEngine.h"

@interface WBVideoMixAudioEngine ()

@property (nonatomic, readwrite, strong) AVMutableComposition *composition;
@property (nonatomic, readwrite, strong) AVMutableVideoComposition *videoComposition;
@property (nonatomic, readwrite, strong) AVMutableAudioMix *audioMix;

@end

@implementation WBVideoMixAudioEngine{
    AVPlayerItem *_currentItem;
    
    AVMutableCompositionTrack *_comTrack1;
    AVMutableCompositionTrack *_comTrack2;
    
    CGFloat _videoVolume;
    CGFloat _musicVolume;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _videoVolume = 1.0;
        _musicVolume = 0.1;
    }
    return self;
}


- (void)buildTransitionComposition:(AVMutableComposition *)composition andVideoComposition:(AVMutableVideoComposition *)videoComposition andAudioMix:(AVMutableAudioMix *)audioMix
{
    // Add two video tracks and two audio tracks.
    AVMutableCompositionTrack *compositionVideoTracks = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTracks[2];
    compositionAudioTracks[0] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    compositionAudioTracks[1] = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    _comTrack1 = compositionAudioTracks[0];
    _comTrack2 = compositionAudioTracks[1];
    
    // Place clips into alternating video & audio tracks in composition, overlapped by transitionDuration.
    {
        AVURLAsset *asset = self.videoAsset;
        
        AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        NSError* error;
        [compositionVideoTracks insertTimeRange:self.videoTimeRange ofTrack:videoTrack atTime:kCMTimeZero error:&error];
        
        AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [_comTrack1 insertTimeRange:self.videoTimeRange ofTrack:audioTrack atTime:kCMTimeZero error:&error];
        
        if (self.musicAsset) {
            AVAssetTrack *musicTrack = [[self.musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
            if (musicTrack) {
                [_comTrack2 insertTimeRange:self.videoTimeRange ofTrack:musicTrack atTime:kCMTimeZero error:&error];
            }
        }
    }
    
    NSMutableArray *instructions = [NSMutableArray array];
    
    AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    passThroughInstruction.timeRange = self.videoTimeRange;
    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTracks];
    passThroughInstruction.layerInstructions = [NSArray arrayWithObject:passThroughLayer];
    [instructions addObject:passThroughInstruction];
    
    NSMutableArray<AVAudioMixInputParameters *> *trackMixArray = [NSMutableArray<AVAudioMixInputParameters *> array];
    {
        AVMutableAudioMixInputParameters *trackMix1 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:_comTrack1];
        trackMix1.trackID = _comTrack1.trackID;
        [trackMix1 setVolume:_videoVolume atTime:kCMTimeZero];
        [trackMixArray addObject:trackMix1];
        
        AVMutableAudioMixInputParameters *trackMix2 = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:_comTrack2];
        trackMix2.trackID = _comTrack2.trackID;
        [trackMix2 setVolume:_musicVolume atTime:kCMTimeZero];
        [trackMixArray addObject:trackMix2];
    }
    
    audioMix.inputParameters = trackMixArray;
    videoComposition.instructions = instructions;
}

- (void)setVideoVolume:(CGFloat)volume {
    // https://stackoverflow.com/questions/33347256/avmutableaudiomixinputparameters-setvolume-doesnt-work-with-audio-file-ios-9
    NSMutableArray *allAudioParams = [NSMutableArray array];
    
    AVMutableAudioMixInputParameters *audioInputParams =
    [AVMutableAudioMixInputParameters audioMixInputParameters];
    [audioInputParams setTrackID:_comTrack1.trackID];
    _videoVolume = volume;
    [audioInputParams setVolume:_videoVolume atTime:kCMTimeZero];
    [allAudioParams addObject:audioInputParams];
    
    AVMutableAudioMixInputParameters *audioInputParams2 =
    [AVMutableAudioMixInputParameters audioMixInputParameters];
    [audioInputParams2 setTrackID:_comTrack2.trackID];
    [audioInputParams2 setVolume:_musicVolume atTime:kCMTimeZero];
    [allAudioParams addObject:audioInputParams2];
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    
    [_currentItem setAudioMix:audioMix];
}

- (void)setMusicVolume:(CGFloat)volume {
    NSMutableArray *allAudioParams = [NSMutableArray array];
    
    AVMutableAudioMixInputParameters *audioInputParams =
    [AVMutableAudioMixInputParameters audioMixInputParameters];
    [audioInputParams setTrackID:_comTrack1.trackID];
    [audioInputParams setVolume:_videoVolume atTime:kCMTimeZero];
    [allAudioParams addObject:audioInputParams];
    
    AVMutableAudioMixInputParameters *audioInputParams2 =
    [AVMutableAudioMixInputParameters audioMixInputParameters];
    [audioInputParams2 setTrackID:_comTrack2.trackID];
    _musicVolume = volume;
    [audioInputParams2 setVolume:_musicVolume atTime:kCMTimeZero];
    [allAudioParams addObject:audioInputParams2];
    
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    [audioMix setInputParameters:allAudioParams];
    
    [_currentItem setAudioMix:audioMix];
}

- (void)buildCompositionObjectsForPlayback
{
    if (!self.videoAsset) {
        self.composition = nil;
        self.videoComposition = nil;
        return;
    }
    
    AVAssetTrack *videoTrack = [[self.videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize naturalSize = videoTrack.naturalSize;
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = nil;
    AVMutableAudioMix *audioMix = nil;
    
    composition.naturalSize = naturalSize;
    
    videoComposition = [AVMutableVideoComposition videoComposition];
    audioMix = [AVMutableAudioMix audioMix];
    
    [self buildTransitionComposition:composition andVideoComposition:videoComposition andAudioMix:audioMix];
    
    if (videoComposition) {
        videoComposition.frameDuration = CMTimeMake(1, 30);
        videoComposition.renderSize = naturalSize;
    }
    
    self.composition = composition;
    self.videoComposition = videoComposition;
    self.audioMix = audioMix;
}

- (AVPlayerItem *)playerItem {
    if (!_currentItem) {
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
        playerItem.videoComposition = self.videoComposition;
        playerItem.audioMix = self.audioMix;
        _currentItem = playerItem;
    }
    return _currentItem;
}

- (void)exportAtPath:(NSString *)outputPath completion:(void (^)(BOOL success))completion {    if (!outputPath) {
        completion(NO);
        return;
    }
    
    NSURL *outputFileUrl = [NSURL fileURLWithPath:outputPath];
    
    AVAssetExportSession *_assetExport =[[AVAssetExportSession alloc]initWithAsset:self.composition presetName:AVAssetExportPreset1280x720];
    _assetExport.outputFileType = AVFileTypeMPEG4;
    _assetExport.audioMix = _currentItem.audioMix;
    _assetExport.outputURL = outputFileUrl;
    _assetExport.shouldOptimizeForNetworkUse = YES;
    
    [_assetExport exportAsynchronouslyWithCompletionHandler:^{
        
        NSLog(@"=========================== \n AVAssetExportSession exportAsynchronouslyWithCompletionHandler Status %ld",(long)_assetExport.status);
        switch (_assetExport.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"exporter Failed");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(YES);
                });
                break;
        }
    }];
}

@end
