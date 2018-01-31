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
extern CFTimeInterval from_load_to_first_rendered_time;
@interface HMDLoadTracker : NSObject

@end
