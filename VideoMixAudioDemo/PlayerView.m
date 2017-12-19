//
//  PlayerView.m
//  VideoMixAudioDemo
//
//  Created by lucifron on 2017/12/18.
//  Copyright © 2017年 lucifron. All rights reserved.
//

#import "PlayerView.h"

@implementation PlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

@end
