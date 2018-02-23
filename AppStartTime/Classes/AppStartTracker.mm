//
//
//  Created by 谢俊逸 on 30/1/2018.
//

#import "AppStartTracker.h"
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <dlfcn.h>
#include <vector>
#include <unistd.h>
#include <mach-o/getsect.h>
#import <objc/message.h>
#include <mach/mach_time.h>

#ifdef __cplusplus
extern "C" {
#endif
#ifdef __cplusplus
}
#endif

// rendered_time == after viewDidAppear: time
CFTimeInterval from_load_to_first_rendered_time;
CFTimeInterval from_didFinshedLaunching_to_first_rendered_time;
CFTimeInterval test_didFinshlaunching_to_first_rendered_time;
CFTimeInterval from_load_to_didFinshedLaunching_time;
dispatch_source_t timer;



start_time_log_t *start_time_log = NULL;


#pragma mark CppInitialize Time

NSMutableArray *cpp_init_infos;
static NSTimeInterval sSumInitTime;

extern "C"
const char* getallinitinfo(){
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [cpp_init_infos addObject:[NSString stringWithFormat:@"SumInitTime=%@",@(sSumInitTime)]];
  });
  
  NSString *msg = [NSString stringWithFormat:@"%@",cpp_init_infos];
  return msg.UTF8String;
}
extern "C"
{
  
  void monitorAppStartTime() {
    test_didFinshlaunching_to_first_rendered_time = CFAbsoluteTimeGetCurrent();
    from_didFinshedLaunching_to_first_rendered_time = CFAbsoluteTimeGetCurrent();
    from_load_to_didFinshedLaunching_time = CFAbsoluteTimeGetCurrent() - from_load_to_didFinshedLaunching_time;

    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
      from_load_to_first_rendered_time = CFAbsoluteTimeGetCurrent() - from_load_to_first_rendered_time;
      from_didFinshedLaunching_to_first_rendered_time = CFAbsoluteTimeGetCurrent() - from_didFinshedLaunching_to_first_rendered_time;
#ifdef DEBUG
      NSLog(@"AppstartTime 首屏渲染记录 \n test_didFinshlaunching_to_first_rendered_time(viewDidAppear) %f \n APPStartTime Log from_didFinshedLaunching_to_first_rendered_time %f \n APPStartTime Log from_load_to_first_rendered_time %f", test_didFinshlaunching_to_first_rendered_time,from_didFinshedLaunching_to_first_rendered_time, from_load_to_first_rendered_time);
#else
#endif
      if (start_time_log){
        start_time_log(from_load_to_first_rendered_time,from_didFinshedLaunching_to_first_rendered_time,test_didFinshlaunching_to_first_rendered_time,from_load_to_didFinshedLaunching_time,objc_load_infos,cpp_init_infos);
      }
      
      dispatch_suspend(timer);
    });
    dispatch_resume(timer);
  }

}



using namespace std;
#ifndef __LP64__
typedef uint32_t MemoryType;
#else /* defined(__LP64__) */
typedef uint64_t MemoryType;
#endif /* defined(__LP64__) */


static std::vector<MemoryType> *g_initializer;
static int g_cur_index;
static MemoryType g_aslr;



struct MyProgramVars
{
  const void*    mh;
  int*      NXArgcPtr;
  const char***  NXArgvPtr;
  const char***  environPtr;
  const char**  __prognamePtr;
};

typedef void (*OriginalInitializer)(int argc, const char* argv[], const char* envp[], const char* apple[], const MyProgramVars* vars);

void myInitFunc_Initializer(int argc, const char* argv[], const char* envp[], const char* apple[], const struct MyProgramVars* vars){
  ++g_cur_index;
  OriginalInitializer func = (OriginalInitializer)g_initializer->at(g_cur_index);
  
  CFTimeInterval start = CFAbsoluteTimeGetCurrent();
  
  func(argc,argv,envp,apple,vars);
  
  CFTimeInterval end = CFAbsoluteTimeGetCurrent();
  sSumInitTime += 1000.0 * (end-start);
  NSString *cost = [NSString stringWithFormat:@"%p=%@",func,@(1000.0*(end - start))];
  [cpp_init_infos addObject:cost];
}

#pragma mark Fix
void scanAllMacho(void) {
  uint32_t count = _dyld_image_count();
  for (uint32_t i = 0; i < count; i++) {
    Dl_info info;
    dladdr((const void *)scanAllMacho, &info);
    
#ifndef __LP64__
    const struct mach_header *mhp = _dyld_get_image_header(i); // both works as below line
//    const struct mach_header *mhp = (struct mach_header*)info.dli_fbase;
    unsigned long size = 0;
    MemoryType *memory = (uint32_t*)getsectiondata(mhp, "__DATA", "__mod_init_func", & size);
#else /* defined(__LP64__) */
    const struct mach_header_64 *mhp = (mach_header_64 *)_dyld_get_image_header(i); // both works as below line
    unsigned long size = 0;
    MemoryType *memory = (uint64_t*)getsectiondata(mhp, "__DATA", "__mod_init_func", & size);
#endif /* defined(__LP64__) */
    for(int idx = 0; idx < size/sizeof(void*); ++idx){
      MemoryType original_ptr = memory[idx];
      g_initializer->push_back(original_ptr);
      memory[idx] = (MemoryType)myInitFunc_Initializer;
    }
    [cpp_init_infos addObject:[NSString stringWithFormat:@"ASLR=%p",mhp]];
    g_aslr = (MemoryType)mhp;
    
  }
}
#pragma mark OC Load Time

NSTimeInterval app_load_to_didFinshLaunch_time;
static uint64_t loadTime;
static uint64_t applicationRespondedTime = -1;
static mach_timebase_info_data_t timebaseInfo;

static inline NSTimeInterval MachTimeToSeconds(uint64_t machTime) {
  return ((machTime / 1e9) * timebaseInfo.numer) / timebaseInfo.denom;
}


unsigned int cls_count;
const char **classes;

NSMutableArray *objc_load_infos;

@implementation HMDLoadTracker

+ (void)load {
  from_load_to_first_rendered_time = CFAbsoluteTimeGetCurrent();
  from_load_to_didFinshedLaunching_time = CFAbsoluteTimeGetCurrent();
  loadTime = mach_absolute_time();
  mach_timebase_info(&timebaseInfo);
  @autoreleasepool {
    __block id obs;
    obs = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                            object:nil queue:nil
                                                        usingBlock:^(NSNotification *note) {
                                                          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                            applicationRespondedTime = mach_absolute_time();
                                                            app_load_to_didFinshLaunch_time =  MachTimeToSeconds(applicationRespondedTime - loadTime);

                                                          });
                                                          [[NSNotificationCenter defaultCenter] removeObserver:obs];
                                                        }];
  }

  
  objc_load_infos = [[NSMutableArray alloc] init];
  
  int imageCount = (int)_dyld_image_count();
  
  for(int iImg = 0; iImg < imageCount; iImg++) {
    
    const char* path = _dyld_get_image_name((unsigned)iImg);
    NSString *imagePath = [NSString stringWithUTF8String:path];
    
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* bundlePath = [mainBundle bundlePath];
    
    if ([imagePath containsString:bundlePath] && ![imagePath containsString:@".dylib"]) {
      classes = objc_copyClassNamesForImage(path, &cls_count);
      
      for (int i = 0; i < cls_count; i++) {
        NSString *className = [NSString stringWithCString:classes[i] encoding:NSUTF8StringEncoding];
        if (![className isEqualToString:@""] && className) {
          Class cls = object_getClass(NSClassFromString(className));
          
          SEL originalSelector = @selector(load);
          SEL swizzledSelector = @selector(LDAPM_Load);
          
          Method originalMethod = class_getClassMethod(cls, originalSelector);
          Method swizzledMethod = class_getClassMethod([self class], swizzledSelector);
          
          BOOL hasMethod = class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
          
          if (!hasMethod) {
            BOOL didAddMethod = class_addMethod(cls,
                                                swizzledSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod));
            
            if (didAddMethod) {
              swizzledMethod = class_getClassMethod(cls, swizzledSelector);
              
              method_exchangeImplementations(originalMethod, swizzledMethod);
            }
          }
          
        }
      }
    }
  }
  // after load
  // initializer
  cpp_init_infos = [NSMutableArray new];
  g_initializer = new std::vector<MemoryType>();
  g_cur_index = -1;
  g_aslr = 0;
  scanAllMacho();
  
}

+ (void)LDAPM_Load {
  
  CFAbsoluteTime start = mach_absolute_time();
  [self LDAPM_Load];
  CFAbsoluteTime end = mach_absolute_time();
  NSDictionary *infoDic = @{@"st":@(start),
                            @"et":@(end),
                            @"interval_second":@(MachTimeToSeconds(end - start)),
                            @"name":NSStringFromClass([self class])
                            };
  
  [objc_load_infos addObject:infoDic];
}





@end

