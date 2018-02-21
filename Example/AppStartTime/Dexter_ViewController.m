//
//  Dexter_ViewController.m
//  AppStartTime
//
//  Created by junyixie on 01/30/2018.
//  Copyright (c) 2018 junyixie. All rights reserved.
//

#import "Dexter_ViewController.h"
#import "AppStartTracker.h"
#import "Dexter_DrawRectTest.h"

@interface Dexter_ViewController ()

@end

@implementation Dexter_ViewController

//+ (void)load {
//  
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
//  for (int i = 0; i < 1000; i ++) {
//    NSLog(@"123");
//  }
  
  self.view.backgroundColor = [UIColor redColor];
	
  Dexter_DrawRectTest *view_draw_rect = [[Dexter_DrawRectTest alloc] initWithFrame:CGRectMake(0, 100, 100, 100)];
  [self.view addSubview: view_draw_rect];
  NSLog(@"viewdidload");
  // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  NSLog(@"didlayoutsubviews");
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  test_didfinshlaunching_to_first_rendered_time = CFAbsoluteTimeGetCurrent() - test_didfinshlaunching_to_first_rendered_time;
  NSLog(@"viewDidAppear");

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  NSLog(@" from_load_to_first_rendered_time %f", from_load_to_first_rendered_time);
  NSLog(@" test_standard_load_to_first_rendered_time %f", test_didfinshlaunching_to_first_rendered_time);
  
  self.view.backgroundColor = [UIColor whiteColor];
}
@end
