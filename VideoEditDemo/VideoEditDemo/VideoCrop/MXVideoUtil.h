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

/**
 根据 phasset 获取 video 的URL
 
 @param phasset 视频 phasset
 @param resultHandler 结果URL回调
 */
+ (void)fetchVideoAssetURLWith:(PHAsset *)phasset resultHandler:(void (^)(NSURL*videoURL))resultHandler;


/**
 视频裁剪函数一
 
 @param videoPath 视频地址
 @param startTime 裁剪开始时间（秒）
 @param endTime 裁剪结束时间（秒）
 @param videoSize 裁剪视频大小
 @param fileName 裁剪生成文件名
 @param shouldScale 是否按比例裁剪
 */
+ (void)cropVideoWithVideoPath:(NSURL*)videoPath startTime:(float)startTime endTime:(float)endTime size:(CGSize)videoSize fileName:(NSString*)fileName shouldScale:(BOOL)shouldScale resultHandler:(void (^)(NSURL*outputURL, NSError*error))resultHandler;


/**
 视频裁剪函数二
 
 @param videoPath 视频路径
 @param startTime 开始裁剪时间（秒）
 @param durationTime 裁剪时间长度（秒）,如果为0，则表示裁剪到视频结束
 @param fileName 生成视频名字
 @param resultHandler 裁剪结果回调
 */
+ (void)cropVideoWithVideoPath:(NSURL*)videoPath startTime:(float)startTime durationTime:(float)durationTime fileName:(NSString*)fileName resultHandler:(void (^)(NSURL*outputURL, NSError*error))resultHandler;


/**
 视频拼接函数

 @param firstVideoPath 视频1 的路径
 @param secondVideoPath 视频2 的路径
 @param fileName 生成视频名字
 @param resultHandler 拼接结果回调
 */
+ (void)spliceVideoWithFirstVideoPath:(NSURL*)firstVideoPath secondVideoPath:(NSURL*)secondVideoPath fileName:(NSString*)fileName resultHandler:(void (^)(NSURL*outputURL, NSError*error))resultHandler;


/**
 保存视频到相册
 
 @param videoURL 视频地址
 */
+ (void)saveToPhotoLibrary:(NSURL *)videoURL resultHandler:(void (^)(NSError*error))resultHandler;

+ (NSError *)createNSErrorWithCode:(NSInteger)code errorReason:(NSString *)reason;

@end

NS_ASSUME_NONNULL_END
