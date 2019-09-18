//
//  FrameEditCell.m
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/18.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import "FrameEditCell.h"


@interface FrameEditCell ()

@property (nonatomic,strong) UIImageView * thumbnail;

@end

@implementation FrameEditCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    _image = image;
    _thumbnail.image = image;
}

- (void)setupSubviews {
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.thumbnail = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    [self.contentView addSubview:self.thumbnail];
}

@end
