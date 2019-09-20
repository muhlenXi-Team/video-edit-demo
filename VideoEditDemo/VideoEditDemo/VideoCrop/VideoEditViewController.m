//
//  VideoEditViewController.m
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/17.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import "VideoEditViewController.h"
#import "FrameEditCell.h"
#import "FrameHanderView.h"
#import <AVKit/AVKit.h>
#import "MXVideoUtil.h"
#import <MBProgressHUD/MBProgressHUD.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kEditBlueViewWidth 16.0
// 最短裁剪视频长度
#define KCropMinSeconds 2.0
// 最长视频裁剪长度
#define kCropMaxSeconds 10

@interface VideoEditViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic,strong) AVPlayer *player;
@property (nonatomic,strong) AVPlayerLayer * playerLayer;

@property (nonatomic,assign) BOOL  isPlaying;

@property (nonatomic, strong) UIView * editView;
@property (nonatomic,strong) UICollectionView *frameCollectionView;
@property (nonatomic, strong) NSMutableArray *framesArray;

@property (nonatomic,strong) FrameHanderView *leftHander;
@property (nonatomic,strong) FrameHanderView *rightHander;
@property (nonatomic, strong) UIView *progressLineView;

@property (nonatomic,assign) CGFloat editMinWidth;
@property (nonatomic,assign) CGFloat editMaxWidth;

@property (nonatomic,assign) float videoTotalTime;
@property (nonatomic, assign) float timescale;

@end

@implementation VideoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavi];
    [self setupPlayer];
    [self setupEditView];
    [self fetchVideoFrames];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

#pragma mark - help method

- (void)setupNavi {
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.title = @"视频裁剪";
    
    UIBarButtonItem *save = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveBarButtonItemAction)];
    self.navigationItem.rightBarButtonItem = save;
}

- (void)setupPlayer {
    AVPlayerItem *playItem = [[AVPlayerItem alloc] initWithURL:self.videoUrl];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.playerLayer];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    self.videoTotalTime = asset.duration.value/asset.duration.timescale;
    self.timescale = asset.duration.timescale;
    
    // 最长s 最短s
    CGFloat totalWidth = kScreenWidth;
    self.editMinWidth = totalWidth * KCropMinSeconds/self.videoTotalTime;
    if (self.videoTotalTime > kCropMaxSeconds) {
        self.editMaxWidth = totalWidth * kCropMaxSeconds/self.videoTotalTime;
    } else {
        self.editMaxWidth = totalWidth-self.leftHander.frame.size.width;
    }
    
    CMTime time = CMTimeMake(1.0, asset.duration.timescale);
    __weak typeof(self)  weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:time queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        // 调整进度条
        CGFloat nowSeconds = CMTimeGetSeconds(weakSelf.player.currentTime);
        CGFloat percent = nowSeconds / weakSelf.videoTotalTime;
        CGFloat totalWidth = kScreenWidth;
        
        CGRect progressFrame = CGRectMake(totalWidth*percent, 4, 4, weakSelf.leftHander.frame.size.height);
        if (weakSelf.isPlaying) {
            [weakSelf updateProgressLineViewFrame:progressFrame];
        }
        
        // 到结束时间重新开始
        CGFloat endSeconds = (weakSelf.rightHander.frame.origin.x)/totalWidth*weakSelf.videoTotalTime;
        CGFloat beginSeconds = (weakSelf.leftHander.frame.size.width)/totalWidth*weakSelf.videoTotalTime;
        if (nowSeconds > endSeconds) {
            CMTime time = CMTimeMakeWithSeconds(beginSeconds, weakSelf.timescale);
            percent = beginSeconds / weakSelf.videoTotalTime;
            progressFrame = CGRectMake(totalWidth*percent, 4, 4, weakSelf.leftHander.frame.size.height);
            [weakSelf updateProgressLineViewFrame:progressFrame];
            [weakSelf.player seekToTime:time completionHandler:^(BOOL finished) {
                [weakSelf play];
            }];
        }
        
        //NSLog(@"%f",CMTimeGetSeconds(weakSelf.player.currentTime));
    }];
    [self play];
}

- (void) setupEditView {
    CGFloat bottomInset = [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    CGRect editFrame = CGRectMake(0, self.view.bounds.size.height-60-bottomInset, self.view.bounds.size.width, 60);
    self.editView = [[UIView alloc] initWithFrame:editFrame];
    self.editView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.editView.alpha = 0;
    [self.view addSubview:self.editView];
    
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(30, 52);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = 0;
    
    CGRect frame = CGRectMake(4, 4, editFrame.size.width-8, editFrame.size.height-8);
    self.frameCollectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
    self.frameCollectionView.backgroundColor = [UIColor whiteColor];
    self.frameCollectionView.dataSource = self;
    self.frameCollectionView.delegate = self;
    self.frameCollectionView.bounces = NO;
    self.frameCollectionView.showsHorizontalScrollIndicator = NO;
    
    [self.frameCollectionView registerClass:[FrameEditCell class] forCellWithReuseIdentifier:@"Cell"];
    
    [self.editView addSubview:self.frameCollectionView];
    
    CGRect leftFrame = CGRectMake(0, 4, kEditBlueViewWidth, frame.size.height);
    self.leftHander = [[FrameHanderView alloc] initWithFrame:leftFrame handerLeft:YES];
    self.leftHander.userInteractionEnabled = YES;
    UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(leftPanGestureHandler:)];
    [self.leftHander addGestureRecognizer:leftPan];
    [self.editView addSubview:self.leftHander];
    
    CGFloat rightX = self.leftHander.frame.size.width+self.editMinWidth;
    CGRect rightFrame = CGRectMake(rightX, 4, self.editView.bounds.size.width-rightX, frame.size.height);
    self.rightHander = [[FrameHanderView alloc] initWithFrame:rightFrame handerLeft:NO];
    self.rightHander.userInteractionEnabled = YES;
    UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rightPanGestureHandler:)];
    [self.rightHander addGestureRecognizer:rightPan];
    [self.editView addSubview:self.rightHander];
    
    CGRect progressFrame = CGRectMake(leftFrame.size.width, 4, 4, leftFrame.size.height);
    self.progressLineView = [[UIView alloc] init];
    self.progressLineView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.8];
    self.progressLineView.frame = progressFrame;
    [self.editView addSubview:self.progressLineView];
}

- (void)fetchVideoFrames {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    float videoTotalTime = asset.duration.value/asset.duration.timescale;
    CGFloat cellWidth = 30;
    
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.maximumSize = CGSizeMake(cellWidth, 52);
    generator.appliesPreferredTrackTransform = YES;
    generator.requestedTimeToleranceAfter = kCMTimeZero;
    generator.requestedTimeToleranceBefore = kCMTimeZero;
    
    NSInteger totalFrame = self.view.frame.size.width/cellWidth + 1;
    NSMutableArray *timeArray = [NSMutableArray array];
    self.framesArray = [NSMutableArray array];
    float per = videoTotalTime / totalFrame;
    for(int i = 0; i < totalFrame; i++) {
        CMTime time = CMTimeMake(i*asset.duration.timescale*per, asset.duration.timescale);
        NSValue *value = [NSValue valueWithCMTime:time];
        [timeArray addObject:value];
    }
    
    [generator generateCGImagesAsynchronouslyForTimes:timeArray completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *image_ = [UIImage imageWithCGImage:image];
            [self.framesArray addObject:image_];
            
            if (self.framesArray.count == timeArray.count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.editView.alpha = 1.0;
                    [self.frameCollectionView reloadData];
                });
            }
        }
        if (result == AVAssetImageGeneratorFailed) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
        }
        
        if (result == AVAssetImageGeneratorCancelled) {
            NSLog(@"AVAssetImageGeneratorCancelled");
        }
    }];
    
}

// 调整播放进度
- (void) seekToPlayer {
    float seconds = self.videoTotalTime*(self.leftHander.frame.size.width/self.editView.frame.size.width);
    CMTime time = CMTimeMakeWithSeconds(seconds, self.timescale);
    [self.player seekToTime:time];
}

- (void)updateProgressLineViewFrame:(CGRect)frame {
    CGFloat leftLimit = self.leftHander.frame.size.width;
    CGFloat rightLimit = self.rightHander.frame.origin.x;
    CGFloat rightPoint = frame.origin.x + frame.size.width;
    CGFloat leftPoint = frame.origin.x;
    if (leftPoint >= leftLimit && rightPoint <= rightLimit) {
        self.progressLineView.frame = frame;
    }
}

- (void)play {
    [self.player play];
    self.isPlaying = YES;
}

- (void)pause {
    [self.player pause];
    self.isPlaying = NO;
}

- (void)showToast:(NSString *)message {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = message;
    [hud hideAnimated:YES afterDelay:1.0];
}

- (void)showFinishAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"新视频已经保存到相册了" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:Nil];
}

#pragma mark - event

- (void) saveBarButtonItemAction {
    [self pause];
    
    CGFloat totalWidth = kScreenWidth-kEditBlueViewWidth*2;
    // 到结束时间重新开始
    CGFloat endSeconds = (self.rightHander.frame.origin.x-kEditBlueViewWidth)/totalWidth*self.videoTotalTime;
    CGFloat beginSeconds = (self.leftHander.frame.size.width-kEditBlueViewWidth)/totalWidth*self.videoTotalTime;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"process...";
    
    [MXVideoUtil cropVideoWithVideoPath:self.videoUrl startTime:beginSeconds endTime:endSeconds size:CGSizeZero fileName:@"cropedVideo" shouldScale:YES resultHandler:^(NSURL *outputURL, NSError *error) {
        if (error == nil) {
            [MXVideoUtil saveToPhotoLibrary:outputURL resultHandler:^(NSError *error) {
                [hud hideAnimated:YES];
                if (error == nil) {
                    [self showFinishAlert];
                } else {
                    [self showToast:error.localizedDescription];
                }
            }];
        } else {
            [hud hideAnimated:YES];
            [self showToast:error.localizedDescription];
        }
    }];
}

- (void)leftPanGestureHandler:(UIPanGestureRecognizer *)pan {
    switch (pan.state) {
        case UIGestureRecognizerStateChanged: {
            [self pause];
            
            CGPoint translation = [pan translationInView:self.editView];
            
            CGFloat maxWidth = kScreenWidth-kEditBlueViewWidth-self.editMinWidth;
            CGRect leftFrame = self.leftHander.frame;
            CGFloat nextWidth = leftFrame.size.width+translation.x;
            if (nextWidth>= kEditBlueViewWidth && nextWidth <= maxWidth) {
                leftFrame.size.width += translation.x;
                self.leftHander.frame = leftFrame;
                
                CGRect progressFrame = CGRectMake(leftFrame.origin.x+leftFrame.size.width, 4, 4, leftFrame.size.height);
                self.progressLineView.frame = progressFrame;
            }
            
            // 确保剪切的宽度在最大和最小之间
            CGFloat cropWidth = kScreenWidth-self.rightHander.frame.size.width-self.leftHander.frame.size.width;
            CGRect rightFrame = self.rightHander.frame;
            if (cropWidth >= self.editMaxWidth) {
                rightFrame.origin.x = self.leftHander.frame.size.width+self.editMaxWidth;
                rightFrame.size.width = self.editView.bounds.size.width-rightFrame.origin.x;
                self.rightHander.frame = rightFrame;
            }
            if (cropWidth <= self.editMinWidth) {
                if (rightFrame.origin.x <= self.editView.bounds.size.width-kEditBlueViewWidth) {
                    rightFrame.origin.x = self.leftHander.frame.size.width+self.editMinWidth;
                    rightFrame.size.width = self.editView.bounds.size.width-rightFrame.origin.x;
                    self.rightHander.frame = rightFrame;
                }
            }
            
            [pan setTranslation:CGPointZero inView:self.editView];
            
            [self seekToPlayer];
        }
            break;
        case UIGestureRecognizerStateEnded:
           [self play];
            break;
        default:
            break;
    }
}

- (void) rightPanGestureHandler:(UIPanGestureRecognizer *)pan {
    switch (pan.state) {
        case UIGestureRecognizerStateChanged: {
            [self pause];
            
            CGPoint translation = [pan translationInView:self.editView];
            
            // 设置右边蓝色把手x坐标
            CGFloat maxRightX = self.editView.bounds.size.width-kEditBlueViewWidth;
            CGRect rightFrame = self.rightHander.frame;
            CGFloat nextX = rightFrame.origin.x+translation.x;
            // 确保没有滑到最右边
            if (nextX >= (kEditBlueViewWidth+self.editMinWidth) && nextX <= maxRightX) {
                rightFrame.origin.x += translation.x;
                rightFrame.size.width = self.editView.bounds.size.width-rightFrame.origin.x;
                self.rightHander.frame = rightFrame;
            }
            
            // 确保剪切的宽度在最大和最小之间
            CGFloat cropWidth = kScreenWidth-self.rightHander.frame.size.width-self.leftHander.frame.size.width;
            CGRect leftFrame = self.leftHander.frame;
            if (cropWidth >= self.editMaxWidth) {
                leftFrame.size.width = kScreenWidth-self.rightHander.frame.size.width - self.editMaxWidth;
                self.leftHander.frame = leftFrame;
            }
            if (cropWidth <= self.editMinWidth) {
                if (leftFrame.size.width >= kEditBlueViewWidth) {
                    CGRect newFrame = CGRectMake(0, 4, kScreenWidth-self.rightHander.frame.size.width-self.editMinWidth, leftFrame.size.height);
                    self.leftHander.frame = newFrame;
                }
            }
            
            CGRect progressFrame = CGRectMake(leftFrame.origin.x+leftFrame.size.width, 4, 4, leftFrame.size.height);
            self.progressLineView.frame = progressFrame;
            
            [pan setTranslation:CGPointZero inView:self.editView];
            
            [self seekToPlayer];
        }
            break;
        case UIGestureRecognizerStateEnded:
            [self play];
            break;
        default:
            break;
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.framesArray.count;
}

- (UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    FrameEditCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    cell.image = self.framesArray[indexPath.item];
    return cell;
}

@end
