//
//  Decoder.h
//  decodeVideoDemo
//
//  Created by HorsonChan on 2019/8/16.
//  Copyright © 2019 Horson. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Decoder : NSObject
+(void)ffmpegOpenFile:(NSString *)filePath outFile:(NSString *)outFilePath;
+(void)decodeAudioOpenFile:(NSString *)filePath outFile:(NSString *)outFilePath;
@end

NS_ASSUME_NONNULL_END
