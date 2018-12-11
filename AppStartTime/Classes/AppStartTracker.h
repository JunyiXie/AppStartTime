//
//
//  Created by 谢俊逸 on 30/1/2018.
//

#import <Foundation/Foundation.h>
/**
 NSDictionary *infoDic = @{@"st":@(start),
 @"et":@(end),
 @"interval_second":@(MachTimeToSeconds(end - start)),
 @"name":NSStringFromClass([self class])
 };
 */
extern NSMutableArray *objc_load_infos;
extern NSTimeInterval app_load_to_didFinshLaunch_time;
extern NSMutableArray *cpp_init_infos;

// first_rendered_time ≈ viewDidAppear:
extern CFTimeInterval from_load_to_first_rendered_time;
extern CFTimeInterval test_didFinshlaunching_to_first_rendered_time;


extern CFTimeInterval from_didFinshedLaunching_to_first_rendered_time;
extern CFTimeInterval from_load_to_didFinshedLaunching_time;

typedef void(start_time_log_t)(CFTimeInterval from_load_to_first_rendered_time,
                               CFTimeInterval from_didFinshedLaunching_to_first_rendered_time,
                               CFTimeInterval test_didFinshlaunching_to_first_rendered_time,
                               CFTimeInterval from_load_to_didFinshedLaunching_time,
                               NSMutableArray *objc_load_infos,
                               NSMutableArray *cpp_init_infos
                               );
extern start_time_log_t *start_time_log;

@interface HMDLoadTracker : NSObject

@end
