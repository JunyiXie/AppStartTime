//
//
//  Created by 谢俊逸 on 30/1/2018.
//

#import "HMDLoadTracker.h"
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <dlfcn.h>
#include <vector>
#include <unistd.h>
#include <mach-o/getsect.h>
#import <objc/message.h>

#ifdef __cplusplus
extern "C" {
#endif
#ifdef __cplusplus
}
#endif


#pragma mark CppInitialize Time

static NSMutableArray *sInitInfos;
static NSTimeInterval sSumInitTime;

extern "C"
const char* getallinitinfo(){
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [sInitInfos addObject:[NSString stringWithFormat:@"SumInitTime=%@",@(sSumInitTime)]];
  });
  
  NSString *msg = [NSString stringWithFormat:@"%@",sInitInfos];
  return msg.UTF8String;
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
  printf("my init func\n");
  ++g_cur_index;
  OriginalInitializer func = (OriginalInitializer)g_initializer->at(g_cur_index);
  
  CFTimeInterval start = CFAbsoluteTimeGetCurrent();
  
  func(argc,argv,envp,apple,vars);
  
  CFTimeInterval end = CFAbsoluteTimeGetCurrent();
  sSumInitTime += 1000.0 * (end-start);
  NSString *cost = [NSString stringWithFormat:@"%p=%@",func,@(1000.0*(end - start))];
  [sInitInfos addObject:cost];
}

static void hookModInitFunc(){
  Dl_info info;
  dladdr((const void *)hookModInitFunc, &info);
  
#ifndef __LP64__
  //        const struct mach_header *mhp = _dyld_get_image_header(0); // both works as below line
  const struct mach_header *mhp = (struct mach_header*)info.dli_fbase;
  unsigned long size = 0;
  MemoryType *memory = (uint32_t*)getsectiondata(mhp, "__DATA", "__mod_init_func", & size);
#else /* defined(__LP64__) */
  const struct mach_header_64 *mhp = (struct mach_header_64*)info.dli_fbase;
  unsigned long size = 0;
  MemoryType *memory = (uint64_t*)getsectiondata(mhp, "__DATA", "__mod_init_func", & size);
#endif /* defined(__LP64__) */
  for(int idx = 0; idx < size/sizeof(void*); ++idx){
    MemoryType original_ptr = memory[idx];
    g_initializer->push_back(original_ptr);
    memory[idx] = (MemoryType)myInitFunc_Initializer;
  }
  
  NSLog(@"zero mod init func : size = %@",@(size));
  
  [sInitInfos addObject:[NSString stringWithFormat:@"ASLR=%p",mhp]];
  g_aslr = (MemoryType)mhp;
}

#pragma mark OC Load Time




#define TIMESTAMP_NUMBER(interval)  [NSNumber numberWithLongLong:interval*1000*1000]



unsigned int load_cls_count;
const char **classes;

NSMutableArray *_loadInfoArray;

@implementation HMDLoadTracker

+ (void)load {
  
  _loadInfoArray = [[NSMutableArray alloc] init];
  
  CFAbsoluteTime time1 =CFAbsoluteTimeGetCurrent();
  
  int imageCount = (int)_dyld_image_count();
  
  for(int iImg = 0; iImg < imageCount; iImg++) {
    
    const char* path = _dyld_get_image_name((unsigned)iImg);
    NSString *imagePath = [NSString stringWithUTF8String:path];
    
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* bundlePath = [mainBundle bundlePath];
    
    if ([imagePath containsString:bundlePath] && ![imagePath containsString:@".dylib"]) {
      classes = objc_copyClassNamesForImage(path, &load_cls_count);
      
      for (int i = 0; i < load_cls_count; i++) {
        NSString *className = [NSString stringWithCString:classes[i] encoding:NSUTF8StringEncoding];
        if (![className isEqualToString:@""] && className) {
          Class cls = object_getClass(NSClassFromString(className));
          
          SEL originalSelector = @selector(load);
          SEL swizzledSelector = @selector(LDAPM_Load);
          
          Method originalMethod = class_getClassMethod(cls, originalSelector);
          Method swizzledMethod = class_getClassMethod(cls, swizzledSelector);
          
          BOOL didAddMethod = class_addMethod(cls, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
          
          if (didAddMethod) {
            class_replaceMethod(cls, @selector(LDAPM_Load), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            
          } else {
            swizzledMethod = class_getClassMethod(cls, swizzledSelector);
            method_exchangeImplementations(originalMethod, swizzledMethod);
          }
          
        }
      }
    }

  }
  
  CFAbsoluteTime time2 =CFAbsoluteTimeGetCurrent();
  
//  NSLog(@"Hook Time:%f",(time2 - time1));
  
  
  // after load
  // initializer
  sInitInfos = [NSMutableArray new];
  g_initializer = new std::vector<MemoryType>();
  g_cur_index = -1;
  g_aslr = 0;
  hookModInitFunc();
  
}
+ (void)LDAPM_Load {
  
  CFAbsoluteTime start =CFAbsoluteTimeGetCurrent();
  
  [self LDAPM_Load];
  
  CFAbsoluteTime end =CFAbsoluteTimeGetCurrent();
  // 时间精度 us
  NSDictionary *infoDic = @{@"st":TIMESTAMP_NUMBER(start),
                            @"et":TIMESTAMP_NUMBER(end),
                            @"name":NSStringFromClass([self class])
                            };
  [_loadInfoArray addObject:infoDic];
}


@end
