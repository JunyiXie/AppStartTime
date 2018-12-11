# AppStartTime

[![CI Status](http://img.shields.io/travis/junyixie/AppStartTime.svg?style=flat)](https://travis-ci.org/junyixie/AppStartTime)
[![Version](https://img.shields.io/cocoapods/v/AppStartTime.svg?style=flat)](http://cocoapods.org/pods/AppStartTime)
[![License](https://img.shields.io/cocoapods/l/AppStartTime.svg?style=flat)](http://cocoapods.org/pods/AppStartTime)
[![Platform](https://img.shields.io/cocoapods/p/AppStartTime.svg?style=flat)](http://cocoapods.org/pods/AppStartTime)

首屏渲染完成的时间的基于 runloop 的原理来进行统计的，我们在  didFinsh 中做了一个 dispatch asyn main queue 的操作，根据 Runloop 的源码可以知道，dispatch asyn main queue block 中的事件是在当次 runloop  即将结束的时候执行的，这个时候渲染已经完成，我们基于打断点和多次数据测试验证了这一方案，是非常准确的。

```
/// RunLoop的实现
int CFRunLoopRunSpecific(runloop, modeName, seconds, stopAfterHandle) {
    
    /// 首先根据modeName找到对应mode
    CFRunLoopModeRef currentMode = __CFRunLoopFindMode(runloop, modeName, false);
    /// 如果mode里没有source/timer/observer, 直接返回。
    if (__CFRunLoopModeIsEmpty(currentMode)) return;
    
    /// 1. 通知 Observers: RunLoop 即将进入 loop。
    __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopEntry);
    
    /// 内部函数，进入loop
    __CFRunLoopRun(runloop, currentMode, seconds, returnAfterSourceHandled) {
        
        Boolean sourceHandledThisLoop = NO;
        int retVal = 0;
        do {
 
            /// 2. 通知 Observers: RunLoop 即将触发 Timer 回调。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeTimers);
            /// 3. 通知 Observers: RunLoop 即将触发 Source0 (非port) 回调。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeSources);
            /// 执行被加入的block
            __CFRunLoopDoBlocks(runloop, currentMode);
            
            /// 4. RunLoop 触发 Source0 (非port) 回调。
            sourceHandledThisLoop = __CFRunLoopDoSources0(runloop, currentMode, stopAfterHandle);
            /// 执行被加入的block
            __CFRunLoopDoBlocks(runloop, currentMode);
 
            /// 5. 如果有 Source1 (基于port) 处于 ready 状态，直接处理这个 Source1 然后跳转去处理消息。
            if (__Source0DidDispatchPortLastTime) {
                Boolean hasMsg = __CFRunLoopServiceMachPort(dispatchPort, &msg)
                if (hasMsg) goto handle_msg;
            }
            
            /// 通知 Observers: RunLoop 的线程即将进入休眠(sleep)。
            if (!sourceHandledThisLoop) {
                __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeWaiting);
            }
            
            /// 7. 调用 mach_msg 等待接受 mach_port 的消息。线程将进入休眠, 直到被下面某一个事件唤醒。
            /// • 一个基于 port 的Source 的事件。
            /// • 一个 Timer 到时间了
            /// • RunLoop 自身的超时时间到了
            /// • 被其他什么调用者手动唤醒
            __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort) {
                mach_msg(msg, MACH_RCV_MSG, port); // thread wait for receive msg
            }
 
            /// 8. 通知 Observers: RunLoop 的线程刚刚被唤醒了。
            __CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopAfterWaiting);
            
            /// 收到消息，处理消息。
            handle_msg:
 
            /// 9.1 如果一个 Timer 到时间了，触发这个Timer的回调。
            if (msg_is_timer) {
                __CFRunLoopDoTimers(runloop, currentMode, mach_absolute_time())
            } 
 
            /// 9.2 如果有dispatch到main_queue的block，执行block。
            else if (msg_is_dispatch) {
                __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
            } 
 
            /// 9.3 如果一个 Source1 (基于port) 发出事件了，处理这个事件
            else {
                CFRunLoopSourceRef source1 = __CFRunLoopModeFindSourceForMachPort(runloop, currentMode, livePort);
                sourceHandledThisLoop = __CFRunLoopDoSource1(runloop, currentMode, source1, msg);
                if (sourceHandledThisLoop) {
                    mach_msg(reply, MACH_SEND_MSG, reply);
                }
            }
            
            /// 执行加入到Loop的block
            __CFRunLoopDoBlocks(runloop, currentMode);
            
 
            if (sourceHandledThisLoop && stopAfterHandle) {
                /// 进入loop时参数说处理完事件就返回。
                retVal = kCFRunLoopRunHandledSource;
            } else if (timeout) {
                /// 超出传入参数标记的超时时间了
                retVal = kCFRunLoopRunTimedOut;
            } else if (__CFRunLoopIsStopped(runloop)) {
                /// 被外部调用者强制停止了
                retVal = kCFRunLoopRunStopped;
            } else if (__CFRunLoopModeIsEmpty(runloop, currentMode)) {
                /// source/timer/observer一个都没有了
                retVal = kCFRunLoopRunFinished;
            }
            
            /// 如果没超时，mode里没空，loop也没被停止，那继续loop。
        } while (retVal == 0);
    }
    
    /// 10. 通知 Observers: RunLoop 即将退出。
    __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);
}
```
```
2018-12-11 11:46:59.878439+0800 AppStartTime_Example[26814:13512418] BeforeTimers
2018-12-11 11:46:59.878564+0800 AppStartTime_Example[26814:13512418] BeforeSources
"doblocks"

2018-12-11 11:47:00.422783+0800 AppStartTime_Example[26814:13512418] didFinishLaunchingWithOptions
2018-12-11 11:47:00.426296+0800 AppStartTime_Example[26814:13512418] viewdidload
"doblocks"

2018-12-11 11:47:00.727314+0800 AppStartTime_Example[26814:13512418] didlayoutsubviews
2018-12-11 11:47:00.727639+0800 AppStartTime_Example[26814:13512418] draw rect
2018-12-11 11:47:00.728606+0800 AppStartTime_Example[26814:13512418] viewDidAppear
"servicing the main queue"

2018-12-11 11:47:02.456146+0800 AppStartTime_Example[26814:13512418] draw
2018-12-11 11:47:02.652840+0800 AppStartTime_Example[26814:13512418] AppstartTime 首屏渲染记录 
 test_didFinshlaunching_to_first_rendered_time(viewDidAppear) 0.305897 
 APPStartTime Log from_didFinshedLaunching_to_first_rendered_time 2.033590 
 APPStartTime Log from_load_to_first_rendered_time 11.108177
"doblocks"
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.


## Installation

AppStartTime is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AppStartTime'
```

## Author

junyixie, xiejunyi19970518@outlook.com


## Some Code Reference 
[Joy_HookLoad](https://github.com/joy0304/Joy-Demo/tree/master/HookLoad)

[everettjf_HookCppInitilizers](https://github.com/everettjf/Yolo/tree/master/HookCppInitilizers)
## License

AppStartTime is available under the MIT license. See the LICENSE file for more info.
