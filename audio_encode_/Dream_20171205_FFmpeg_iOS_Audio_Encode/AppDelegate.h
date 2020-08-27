//
//  AppDelegate.h
//  Dream_20171205_FFmpeg_iOS_Audio_Encode
//
//  Created by Dream on 2017/12/5.
//  Copyright © 2017年 Tz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

