//
//  Dexter_AppDelegate.m
//  AppStartTime
//
//  Created by junyixie on 01/30/2018.
//  Copyright (c) 2018 junyixie. All rights reserved.
//
#import "Dexter_AppDelegate.h"
#import "AppStartTracker.h"
extern void monitorFromLoadToFirstRenderedTime(void);
static void YYRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
//  static dispatch_once_t onceToken;
//  dispatch_once(&onceToken, ^{
  if (activity == kCFRunLoopBeforeSources) {
    NSLog(@"kCFRunLoopBeforeSources");
  } else if (activity == kCFRunLoopBeforeTimers) {
    NSLog(@"kCFRunLoopBeforeTimers");
  } else if (activity == kCFRunLoopBeforeWaiting) {
    NSLog(@"kCFRunLoopBeforeWaiting");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      monitorFromLoadToFirstRenderedTime();
    });
  }
//  });
}
@implementation Dexter_AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//  static dispatch_once_t onceToken;
//  dispatch_once(&onceToken, ^{
    CFRunLoopRef runloop = CFRunLoopGetMain();
    CFRunLoopObserverRef observer;
    
    observer = CFRunLoopObserverCreate(CFAllocatorGetDefault(),
                                       kCFRunLoopBeforeWaiting | kCFRunLoopBeforeTimers | kCFRunLoopBeforeSources
                                       ,
                                       true,      // repeat
                                       0xFFFFFF,  // after CATransaction(2000000)
                                       YYRunLoopObserverCallBack, NULL);
    CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
    CFRelease(observer);
//  });
  
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
