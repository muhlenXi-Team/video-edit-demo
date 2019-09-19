//
//  MXVideoUtil.m
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/17.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import "MXVideoUtil.h"


@implementation MXVideoUtil

/**
 根据 phasset 获取 video 的URL
 
 @param phasset 视频 phasset
 @param resultHandler 结果URL回调
 */
+ (void)fetchVideoAssetURLWith:(PHAsset *)phasset resultHandler:(void (^)(NSURL*videoURL))resultHandler{
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    [[PHImageManager defaultManager] requestAVAssetForVideo:phasset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        AVURLAsset *urlAsset = (AVURLAsset *) asset;
        resultHandler(urlAsset.URL);
    }];
}

/**
 视频裁剪函数
 
 @param videoPath 视频地址
 @param startTime 裁剪开始时间（秒）
 @param endTime 裁剪结束时间（秒）
 @param videoSize 裁剪视频大小
 @param fileName 裁剪生成文件名
 @param shouldScale 是否按比例裁剪
 */
+ (void)cropVideoWithVideoPath:(NSURL*)videoPath startTime:(float)startTime endTime:(float)endTime size:(CGSize)videoSize fileName:(NSString*)fileName shouldScale:(BOOL)shouldScale  resultHandler:(void (^)(NSURL*outputURL, NSError*error))resultHandler {
    
    // 1、生成 videoAsset
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:videoPath options:opts];
    
    // 2、生成裁剪开始时间 裁剪结束时间
    CMTime cropStartTime = CMTimeMakeWithSeconds(startTime, videoAsset.duration.timescale);
    CMTime cropEndTime = CMTimeMakeWithSeconds(endTime, videoAsset.duration.timescale);
    float videoEndTime = videoAsset.duration.value/videoAsset.duration.timescale;
    if (endTime == 0) {
        cropEndTime = CMTimeMakeWithSeconds(videoEndTime, videoAsset.duration.timescale);
    }
    
    // 3、生成 音视频合成对象
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    
    // 4、如有声音，则加入音轨
    if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] > 0) {
        // 提取视频中的音轨
        AVAssetTrack *audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] lastObject];
        // 音视频合成对象加入音轨
        AVMutableCompositionTrack *audioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrack insertTimeRange:CMTimeRangeFromTimeToTime(cropStartTime, cropEndTime) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    }
    
    // 5、提取视频中的视频轨，
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    // 音视频合成对象加入视频轨
    AVMutableCompositionTrack *videoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error;
    [videoTrack insertTimeRange:CMTimeRangeFromTimeToTime(cropStartTime, cropEndTime) ofTrack:videoAssetTrack atTime:kCMTimeZero error:&error];
    
    // 6、生成音视频合成设置对象
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, videoTrack.timeRange.duration);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    
    // 视频缩放比例
    BOOL isVideoAssetVertical = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.d == 0 && (videoTransform.b == 1.0 || videoTransform.b == -1.0) && (videoTransform.c == 1.0 || videoTransform.c == -1.0)) {
        isVideoAssetVertical = YES;
    }
    
    CGSize fixedVideoSize;
    CGSize naturalSize = [[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize];
    if (isVideoAssetVertical) {
        fixedVideoSize = CGSizeMake(naturalSize.height, naturalSize.width);
    } else {
        fixedVideoSize = CGSizeMake(naturalSize.width, naturalSize.height);
    }
    
    float scaleX = 1.0, scaleY = 1.0, scale = 1.0;
    if (shouldScale) {
        if (videoSize.width != 0 && videoSize.height != 0) {
            scaleX = videoSize.width/fixedVideoSize.width;
            scaleY = videoSize.height/fixedVideoSize.height;
            scale = MAX(scaleX, scaleY);
        }
    }
    
    CGAffineTransform preferredTransform = videoAssetTrack.preferredTransform;
    CGAffineTransform transform = CGAffineTransformMake(preferredTransform.a*scale,
                                                        preferredTransform.b*scale,
                                                        preferredTransform.c*scale,
                                                        preferredTransform.d*scale,
                                                        preferredTransform.tx*scale,
                                                        preferredTransform.ty*scale);
    
    // 微信拍摄的视频tx错位，需要修复
    CGRect rect = {{0, 0}, naturalSize};
    CGRect transformedRect = CGRectApplyAffineTransform(rect, transform);
    transform.tx -= transformedRect.origin.x;
    transform.ty -= transformedRect.origin.y;
    
    [layerInstruction setTransform:transform atTime:kCMTimeZero];
    
    mainInstruction.layerInstructions = @[layerInstruction];
    
    // 7、生成 视频合成对象
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    CGSize renderSize = fixedVideoSize;
    if (videoSize.height != 0.0 && videoSize.width != 0.0) {
        renderSize = videoSize;
    }
    // 设置渲染尺寸、合成设置、帧数等
    mutableVideoComposition.renderSize = renderSize;
    mutableVideoComposition.instructions = @[mainInstruction];
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
    // 8、生成视频导出路径并导出视频
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *myPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", fileName]];
    // 有则删除文件
    unlink([myPath UTF8String]);
    NSURL *videoURL = [NSURL fileURLWithPath:myPath];
    // 导出视频
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mutableComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = videoURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mutableVideoComposition;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exporter.status == AVAssetExportSessionStatusCompleted) {
                resultHandler(exporter.outputURL, nil);
            } else {
                NSError *error = [self createNSErrorWithCode:200 errorReason:@"视频导出失败"];
                resultHandler(nil, error);
            }
        });
    }];
}


/**
 保存视频到相册
 
 @param videoURL 视频地址
 */
+ (void)saveToPhotoLibrary:(NSURL *)videoURL resultHandler:(void (^)(NSError*error))resultHandler{
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoURL.path)) {
        NSError *error;
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
        } error:&error];
        if (error) {
            resultHandler(error);
        } else {
            resultHandler(nil);
        }
    } else {
        resultHandler([self createNSErrorWithCode:100 errorReason:@"视频保存相册失败，请设置软件读取相册权限"]);
    }
}

+ (NSError *)createNSErrorWithCode:(NSInteger)code errorReason:(NSString *)reason {
    NSDictionary *info = @{NSLocalizedDescriptionKey : reason };
    NSError *error = [NSError errorWithDomain:@"com.muhlenxi.demo" code:code userInfo:info];
    return error;
}


@end
