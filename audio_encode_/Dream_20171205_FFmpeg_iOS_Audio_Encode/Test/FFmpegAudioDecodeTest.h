//
//  FFmpegAudioDecodeTest.h
//  Dream_20171127_FFmpeg_iOS_Audio_Decode
//
//  Created by Dream on 2017/11/27.
//  Copyright © 2017年 Tz. All rights reserved.
//

#import <Foundation/Foundation.h>

//导入音视频头文件库
//核心库
#include "libavcodec/avcodec.h"
//封装格式处理库
#include "libavformat/avformat.h"
//工具库
#include "libavutil/imgutils.h"
//视频像素数据格式库
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"

@interface FFmpegAudioDecodeTest : NSObject

//音频编码
+(void)ffmpegAudioEncode:(NSString*)inFilePath outFilePath:(NSString*)outFilePath;

@end
