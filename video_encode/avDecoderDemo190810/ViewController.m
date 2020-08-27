//
//  ViewController.m
//  avDecoderDemo190810
//
//  Created by HorsonChan on 2019/8/10.
//  Copyright © 2019 Horson. All rights reserved.
//

#import "ViewController.h"

#import "FFmpegTest.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //测试1
//    [FFmpegTest testConfig];
    //测试2
    NSString *path = [[NSBundle mainBundle]pathForResource:@"Test" ofType:@"mov"];
//    [FFmpegTest ffmpegOpenFile:path];
}


@end
