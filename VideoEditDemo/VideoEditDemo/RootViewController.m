//
//  RootViewController.m
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/20.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import "RootViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface RootViewController ()

@property (nonatomic,assign) BOOL lightOn;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}



- (IBAction)testButtonAction:(id)sender {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    BOOL hasTorch =  [device hasTorch];
    
    if (hasTorch) {
        self.lightOn = !self.lightOn;
        AVCaptureTorchMode mode = self.lightOn ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
        
        [device lockForConfiguration:nil];
        [device setTorchMode:mode];
        [device unlockForConfiguration];
    } else {
        NSLog(@"没有闪光灯");
    }
}

@end
