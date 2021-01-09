//
//  MXVideoUtil.m
//  VideoEditDemo
//
//  Created by muhlenXi on 2019/9/17.
//  Copyright © 2019 muhlenXi. All rights reserved.
//

#import "MXVideoUtil.h"


@implementation MXVideoUtil


+ (void)fetchVideoAssetURLWith:(PHAsset *)phasset resultHandler:(void (^)(NSURL*videoURL))resultHandler{
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    [[PHImageManager defaultManager] requestAVAssetForVideo:phasset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
        AVURLAsset *urlAsset = (AVURLAsset *) asset;
        resultHandler(urlAsset.URL);
    }];
}


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



+ (void)cropVideoWithVideoPath:(NSURL*)videoPath startTime:(float)startTime durationTime:(float)durationTime fileName:(NSString*)fileName resultHandler:(void (^)(NSURL*outputURL, NSError*error))resultHandler  {
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoPath options:opts];
    float videoTotalime = asset.duration.value/asset.duration.timescale;
    
    if (startTime > videoTotalime) {
        NSError *error = [self createNSErrorWithCode:300 errorReason:@"裁剪开始时间超出视频总时间长度"];
        resultHandler(nil, error);
        return;
    }
    
    AVAssetExportSession *export = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *myPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", fileName]];
    // 有则删除文件
    unlink([myPath UTF8String]);
    
    // 如果裁剪时长超出视频裁剪范围，则取视频剩余可裁剪时长
    float maxDuration = videoTotalime - startTime;
    float acturalDuration = MIN(maxDuration, durationTime);
    if(durationTime == 0) {
        acturalDuration = maxDuration;
    }
    
    CMTime start = CMTimeMakeWithSeconds(startTime, 600);
    CMTime duration = CMTimeMakeWithSeconds(acturalDuration, 600);

    CMTimeRange range = CMTimeRangeMake(start, duration);
    export.timeRange = range;
    export.outputURL = [NSURL fileURLWithPath:myPath];
    export.outputFileType = AVFileTypeMPEG4;
    
    
    [export exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (export.status == AVAssetExportSessionStatusCompleted) {
                resultHandler(export.outputURL, nil);
            } else {
                NSError *error = [self createNSErrorWithCode:200 errorReason:@"视频导出失败"];
                resultHandler(nil, error);
            }
        });
    }];
}

+ (void)spliceVideoWithFirstVideoPath:(NSURL*)firstVideoPath secondVideoPath:(NSURL*)secondVideoPath fileName:(NSString*)fileName resultHandler:(void (^)(NSURL*outputURL, NSError*error))resultHandler {
    
    // 创建可变集合对象 Composition
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    // 创建视频轨对象
    AVMutableCompositionTrack *videoCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 创建音频轨对象
    AVMutableCompositionTrack *audioCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // 构建 视频1 视频2 的 asset
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *firstVideoAsset = [[AVURLAsset alloc] initWithURL:firstVideoPath options:opts];
    AVURLAsset *secondVideoAsset = [[AVURLAsset alloc] initWithURL:secondVideoPath options:opts];
    
    // 提取 视频1 视频2 的视频轨数据
    AVAssetTrack *firstVideoAssetTrack = [[firstVideoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVAssetTrack *secondVideoAssetTrack = [[secondVideoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    // 添加 视频1 视频2 的视频轨数据到 视频轨对象中
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration) ofTrack:firstVideoAssetTrack atTime:kCMTimeZero error:nil];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAssetTrack.timeRange.duration) ofTrack:secondVideoAssetTrack atTime:firstVideoAssetTrack.timeRange.duration error:nil];
    
    // 提取 视频1 视频2 的音频轨数据
    AVAssetTrack *firstVideoAudioTrack = [[firstVideoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    AVAssetTrack *secondVideoAudioTrack = [[secondVideoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    // 添加 视频1 视频2 的音频轨数据到 音频轨对象中
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstVideoAudioTrack.timeRange.duration) ofTrack:firstVideoAudioTrack atTime:kCMTimeZero error:nil];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondVideoAudioTrack.timeRange.duration) ofTrack:secondVideoAudioTrack atTime:firstVideoAssetTrack.timeRange.duration error:nil];
    
    // 检查两个 video 的方向，方向不同的 video 不能拼接
    BOOL isFirstVideoPortrait = NO;
    CGAffineTransform firstTransform = firstVideoAssetTrack.preferredTransform;
    if (firstTransform.a == 0 && firstTransform.d == 0 && (firstTransform.b == 1.0 || firstTransform.b == -1.0) && (firstTransform.c == 1.0 || firstTransform.c == -1.0)) {
        isFirstVideoPortrait = YES;
    }
    
    BOOL isSecondVideoPortrait = NO;
    CGAffineTransform secondTransform = secondVideoAssetTrack.preferredTransform;
    if (secondTransform.a == 0 && secondTransform.d == 0 && (secondTransform.b == 1.0 || secondTransform.b == -1.0) && (secondTransform.c == 1.0 || secondTransform.c == -1.0)) {
        isSecondVideoPortrait = YES;
    }
    
    if ((isFirstVideoPortrait && !isSecondVideoPortrait) || (!isFirstVideoPortrait && isSecondVideoPortrait)) {
        NSError *error = [self createNSErrorWithCode:400 errorReason:@"视频方向不一致，无法拼接"];
        resultHandler(nil, error);
        return;
    }
    
    // 构建修正视频尺寸d
    CGSize naturalSizeFirst = firstVideoAssetTrack.naturalSize;
    CGSize naturalSizeSecond = secondVideoAssetTrack.naturalSize;
    CGSize fixedSizeFirst = firstVideoAssetTrack.naturalSize;
    CGSize fixedSizeSecond = secondVideoAssetTrack.naturalSize;
    
    if (isFirstVideoPortrait) {
        fixedSizeFirst = CGSizeMake(firstVideoAssetTrack.naturalSize.height, firstVideoAssetTrack.naturalSize.width);
        fixedSizeSecond = CGSizeMake(secondVideoAssetTrack.naturalSize.height, secondVideoAssetTrack.naturalSize.width);
    }
    
    // 构建视频1 的操作命令
    AVMutableVideoCompositionInstruction *firstVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    firstVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstVideoAssetTrack.timeRange.duration);
    AVMutableVideoCompositionLayerInstruction *firstVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
    
    // 微信拍摄的视频tx错位，需要修复
    CGRect firstRect = {{0, 0}, naturalSizeFirst};
    CGRect firstTransformedRect = CGRectApplyAffineTransform(firstRect, firstTransform);
    firstTransform.tx -= firstTransformedRect.origin.x;
    firstTransform.ty -= firstTransformedRect.origin.y;
    [firstVideoLayerInstruction setTransform:firstTransform atTime:kCMTimeZero];
    
    firstVideoCompositionInstruction.layerInstructions = @[firstVideoLayerInstruction];
    
    
    // 构建视频2 的操作命令
    AVMutableVideoCompositionInstruction * secondVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    secondVideoCompositionInstruction.timeRange = CMTimeRangeMake(firstVideoAssetTrack.timeRange.duration, CMTimeAdd(firstVideoAssetTrack.timeRange.duration, secondVideoAssetTrack.timeRange.duration));
    AVMutableVideoCompositionLayerInstruction *secondVideoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
    
    // 微信拍摄的视频tx错位，需要修复
    CGRect secondRect = {{0, 0}, naturalSizeSecond};
    CGRect secondTransformedRect = CGRectApplyAffineTransform(secondRect, secondTransform);
    secondTransform.tx -= secondTransformedRect.origin.x;
    secondTransform.ty -= secondTransformedRect.origin.y;
    
    [secondVideoLayerInstruction setTransform:secondTransform atTime:firstVideoAssetTrack.timeRange.duration];
    secondVideoCompositionInstruction.layerInstructions = @[secondVideoLayerInstruction];
    
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    mutableVideoComposition.instructions = @[firstVideoCompositionInstruction, secondVideoCompositionInstruction];
    
    
    float renderWidth = MAX(fixedSizeFirst.width, fixedSizeSecond.width);
    float renderHeight = MAX(fixedSizeFirst.height, fixedSizeSecond.height);
    
    mutableVideoComposition.renderSize = CGSizeMake(renderWidth, renderHeight);
    mutableVideoComposition.frameDuration = CMTimeMake(1,30);
    
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
