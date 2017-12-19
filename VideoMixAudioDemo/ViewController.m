//
//  ViewController.m
//  VideoMixAudioDemo
//
//  Created by lucifron on 2017/12/18.
//  Copyright © 2017年 lucifron. All rights reserved.
//

#import "ViewController.h"
@import AVFoundation;
#import "PlayerView.h"
#import "WBVideoMixAudioEngine.h"

@interface ViewController ()

@property (nonatomic, strong) AVPlayer *videoPlayer;
@property (nonatomic, strong) WBVideoMixAudioEngine *mixEngine;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.videoPlayer = [[AVPlayer alloc] init];
    [(PlayerView *)self.view setPlayer:self.videoPlayer];
    
    self.mixEngine = [[WBVideoMixAudioEngine alloc] init];
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"]]];
    AVURLAsset *musicAsset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"music" ofType:@"mp3"]]];
    self.mixEngine.videoAsset = videoAsset;
    self.mixEngine.musicAsset = musicAsset;
    self.mixEngine.videoTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(0, 1), CMTimeMakeWithSeconds(30, 1));
    
    [self.mixEngine buildCompositionObjectsForPlayback];
    AVPlayerItem *playerItem = [self.mixEngine playerItem];
    [self.videoPlayer replaceCurrentItemWithPlayerItem:playerItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.videoPlayer play];
}


#pragma mark - Actions

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.videoPlayer.rate >= 0) {
        [self.videoPlayer pause];
    }else{
        [self.videoPlayer play];
    }
}

- (IBAction)videoVolumeChanged:(UISlider *)sender {
    [self.mixEngine setVideoVolume:sender.value];
}

- (IBAction)musicVolumeChanged:(UISlider *)sender {
    [self.mixEngine setMusicVolume:sender.value];
}

- (IBAction)exportVideo:(id)sender {
    NSString *documentsDirectory =[NSHomeDirectory()
                                   stringByAppendingPathComponent:@"Documents"];
    NSDate *date = [NSDate date];
    NSString *name = [NSString stringWithFormat:@"OutputVideo-%f.mp4",[date timeIntervalSince1970]];
    NSString *outputFilePath = [documentsDirectory stringByAppendingPathComponent:name];
    NSLog(@"Output Path : %@",outputFilePath);

    [self.mixEngine exportAtPath:outputFilePath completion:^(BOOL success) {
        
    }];
    
}

@end
