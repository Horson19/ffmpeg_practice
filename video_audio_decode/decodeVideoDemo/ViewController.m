//
//  ViewController.m
//  decodeVideoDemo
//
//  Created by HorsonChan on 2019/8/16.
//  Copyright © 2019 Horson. All rights reserved.
//

#import "ViewController.h"
#import "Decoder.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    NSString *inPath = [[NSBundle mainBundle]pathForResource:@"Test" ofType:@"mov"];
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
//
//                                                         NSUserDomainMask, YES);
//    NSString *path = [paths objectAtIndex:0];
//    NSString *tmpPath = [path stringByAppendingPathComponent:@"temp"];
//    [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:NULL];
//    NSString* outFilePath = [tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Test.yuv"]];
//
//    [Decoder ffmpegOpenFile:inPath outFile:outFilePath];
    
    NSString *inPath = [[NSBundle mainBundle]pathForResource:@"Test" ofType:@"mov"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         
                                                         NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *tmpPath = [path stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:NULL];
    NSString* outFilePath = [tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Test.pcm"]];
    
    [Decoder decodeAudioOpenFile:inPath outFile:outFilePath];
}


@end
