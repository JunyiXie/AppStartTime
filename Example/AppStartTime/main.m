//
//  main.m
//  AppStartTime
//
//  Created by junyixie on 01/30/2018.
//  Copyright (c) 2018 junyixie. All rights reserved.
//

@import UIKit;
#import "Dexter_AppDelegate.h"

CFTimeInterval time_main_to_firstRendering;

int main(int argc, char * argv[])
{
  time_main_to_firstRendering = CFAbsoluteTimeGetCurrent();
  NSLog(@"time");

    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([Dexter_AppDelegate class]));
    }
}
