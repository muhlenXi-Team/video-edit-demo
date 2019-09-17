//
//  MXVideoUtil.h
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/17.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface MXVideoUtil : NSObject

- (void)fetchVideoAssetURLWith:(PHAsset *)phasset resultHandler:(void (^)(NSURL*videoURL))resultHandler;

- (void)cropVideoWithVideoPath:(NSURL*)videoPath startTime:(float)startTime endTime:(float)endTime size:(CGSize)videoSize fileName:(NSString*)fileName shouldScale:(BOOL)shouldScale;

- (void)saveToPhotoLibrary:(NSURL *) videoURL;

@end

NS_ASSUME_NONNULL_END
