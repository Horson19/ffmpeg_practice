//
//  ViewController.m
//  Dream_20171205_FFmpeg_iOS_Audio_Encode
//
//  Created by Dream on 2017/12/5.
//  Copyright © 2017年 Tz. All rights reserved.
//

#import "ViewController.h"
#import "FFmpegAudioDecodeTest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *inStr= [NSString stringWithFormat:@"Video.bundle/%@",@"Test.pcm"];
    NSString *inPath=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:inStr];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         
                                                         NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *tmpPath = [path stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString* outFilePath = [tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Test.aac"]];
    
    [FFmpegAudioDecodeTest ffmpegAudioEncode:inPath outFilePath:outFilePath];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
