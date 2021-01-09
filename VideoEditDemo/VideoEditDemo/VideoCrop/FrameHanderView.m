//
//  FrameHanderView.m
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/18.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import "FrameHanderView.h"

@interface FrameHanderView ()

@property (nonatomic,assign) BOOL  isLeft;
@property (nonatomic,strong) UIView * blueView;
@property (nonatomic,strong) UIView * whiteLineView;

@end

@implementation FrameHanderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame handerLeft:(BOOL)isLeft{
    if (self = [self initWithFrame:frame]) {
        self.isLeft = isLeft;
        [self setupSubViews];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (self.isLeft) {
        self.blueView.frame = CGRectMake(self.bounds.size.width-16, 0, 16, self.bounds.size.height);
    } else {
        self.blueView.frame = CGRectMake(0, 0, 16, self.bounds.size.height);
    }
}

- (void) setupSubViews {
    self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.blueView = [[UIView alloc] init];
    self.blueView.backgroundColor = [UIColor colorWithRed:39/255.0 green:97/255.0 blue:181/255.0 alpha:1.0];
    if (self.isLeft) {
        self.blueView.frame = CGRectMake(self.bounds.size.width-16, 0, 16, self.bounds.size.height);
    } else {
        self.blueView.frame = CGRectMake(0, 0, 16, self.bounds.size.height);
    }
    [self addSubview:self.blueView];
    
    self.whiteLineView = [[UIView alloc] init];
    self.whiteLineView.backgroundColor = [UIColor whiteColor];
    self.whiteLineView.frame = CGRectMake(7, 12, 2, 28);
    [self.blueView addSubview:self.whiteLineView];
}


@end
