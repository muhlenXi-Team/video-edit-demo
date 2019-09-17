//
//  VideoEditViewController.m
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/17.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import "VideoEditViewController.h"
#import <AVKit/AVKit.h>

@interface VideoEditViewController ()

@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerLayer * playerLayer;

@property (nonatomic,assign) BOOL  isPlaying;
@property (nonatomic,strong) UIButton * playButton;

@end

@implementation VideoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.title = @"视频裁剪";

    [self setupPlayer];
    [self setupPlayButton];
}

- (void)setupPlayer {
    AVPlayerItem *playItem = [[AVPlayerItem alloc] initWithURL:self.videoUrl];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.view.bounds;
    
    [self.view.layer addSublayer:self.playerLayer];
}

- (void)setupPlayButton {
    UIButton *play = [[UIButton alloc] init];
    play.frame = CGRectMake(0, 0, 80, 30);
    play.center = self.view.center;
    
    [play setTitle:@"play" forState:UIControlStateNormal];
    [play setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [play addTarget:self action:@selector(playButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:play];
    self.playButton = play;
}

- (void)playButtonAction {
    if (self.isPlaying == FALSE) {
        [self.player play];
        [self.playButton setTitle:@"pasuse" forState:UIControlStateNormal];
        self.isPlaying = YES;
    } else {
        [self.player pause];
        [self.playButton setTitle:@"play" forState:UIControlStateNormal];
        self.isPlaying = NO;
    }
}

@end
