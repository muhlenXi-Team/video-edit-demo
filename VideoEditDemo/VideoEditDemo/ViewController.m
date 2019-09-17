//
//  ViewController.m
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/17.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import "ViewController.h"
#import "VideoEditViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *videoNameLabel;

@property (nonatomic,strong) NSURL * videoUrl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoNameLabel.numberOfLines = 0;
}


- (IBAction)addVideoAction:(UIBarButtonItem *)sender {
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.videoMaximumDuration = 60.0;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:Nil];
}

- (IBAction)editVideoAction:(id)sender {
    if (self.videoUrl != nil) {
        
        VideoEditViewController *edit = [[VideoEditViewController alloc] init];
        edit.videoUrl = self.videoUrl;
        [self.navigationController pushViewController:edit animated:YES];
        
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"未添加视频" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alert dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [alert addAction:cancel];
        [self presentViewController:alert animated:YES completion:Nil];
    }
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:Nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    
    [picker dismissViewControllerAnimated:YES completion:Nil];
    
    NSURL *videoURL = info[@"UIImagePickerControllerMediaURL"];
    self.videoNameLabel.text = videoURL.absoluteString;
    self.videoUrl = videoURL;
    
    NSLog(@"%@", info);
}

@end
