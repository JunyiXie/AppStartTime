//
//  Dexter_ViewController.m
//  AppStartTime
//
//  Created by junyixie on 01/30/2018.
//  Copyright (c) 2018 junyixie. All rights reserved.
//

#import "Dexter_ViewController.h"
#import "HMDLoadTracker.h"

@interface Dexter_ViewController ()

@end

@implementation Dexter_ViewController

//+ (void)load {
//  
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  NSLog(@"%f", app_load_to_didFinshLaunch_time);
  [objc_load_infos enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    NSLog(@"%@", obj);
    NSLog(@"%f", ((NSNumber *)(obj[@"interval_second"])).floatValue);
  }];
  NSLog(@"%@", cpp_init_infos);

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
