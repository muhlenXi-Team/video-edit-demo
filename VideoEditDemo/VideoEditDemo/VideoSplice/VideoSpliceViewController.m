//
//  VideoSpliceViewController.m
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/21.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import "VideoSpliceViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "MXVideoUtil.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface VideoSpliceViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *urlLabelA;
@property (weak, nonatomic) IBOutlet UILabel *urlLabelB;

@property (nonatomic, strong) NSURL * videoUrlA;
@property (nonatomic, strong) NSURL * videoUrlB;

@property (nonatomic, assign) BOOL isPickingA;
@property (nonatomic, assign) BOOL isPickingB;

@end

@implementation VideoSpliceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

#pragma mark - help methods

- (void) presentVideoPicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.videoMaximumDuration = 60.0;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:Nil];
}

- (void)showAlert:(NSString *) message  {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:Nil];
}

#pragma mark - events

- (IBAction)addVideoAAction:(id)sender {
    self.isPickingA = YES;
    self.isPickingB = NO;
    
    [self presentVideoPicker];
}

- (IBAction)addVideoBAction:(id)sender {
    self.isPickingA = NO;
    self.isPickingB = YES;
    
    [self presentVideoPicker];
}

- (IBAction)apliceVideoAAction:(id)sender {
    if ([self.videoUrlA.absoluteString length] == 0) {
        [self showAlert:@"请添加视频 A"];
        return;
    }
    if ([self.videoUrlB.absoluteString length] == 0) {
        [self showAlert:@"请添加视频 B"];
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"process...";
    
    [MXVideoUtil spliceVideoWithFirstVideoPath:self.videoUrlA secondVideoPath:self.videoUrlB fileName:@"newVideo" resultHandler:^(NSURL * outputURL, NSError * error) {
        if (error == nil) {
            [MXVideoUtil saveToPhotoLibrary:outputURL resultHandler:^(NSError *error) {
                [hud hideAnimated:YES];
                if (error == nil) {
                    [self showAlert:@"已经保存到相册了"];
                } else {
                    [self showAlert:error.localizedDescription];
                }
            }];
        } else {
            [hud hideAnimated:YES];
            [self showAlert:error.localizedDescription];
        }
    }];
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:Nil];
    
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    
    [picker dismissViewControllerAnimated:YES completion:Nil];
    
    NSURL *videoURL = info[@"UIImagePickerControllerMediaURL"];
    
    if(self.isPickingA) {
        self.videoUrlA = videoURL;
        self.urlLabelA.text = videoURL.absoluteString;
    }
    if (self.isPickingB) {
        self.videoUrlB = videoURL;
        self.urlLabelB.text = videoURL.absoluteString;
    }
    
    NSLog(@"%@", info);
}

@end
