# AppStartTime

[![CI Status](http://img.shields.io/travis/junyixie/AppStartTime.svg?style=flat)](https://travis-ci.org/junyixie/AppStartTime)
[![Version](https://img.shields.io/cocoapods/v/AppStartTime.svg?style=flat)](http://cocoapods.org/pods/AppStartTime)
[![License](https://img.shields.io/cocoapods/l/AppStartTime.svg?style=flat)](http://cocoapods.org/pods/AppStartTime)
[![Platform](https://img.shields.io/cocoapods/p/AppStartTime.svg?style=flat)](http://cocoapods.org/pods/AppStartTime)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

AppStartTime is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'AppStartTime'
```

## 思路

[iOS 使用RunLoop来确定首屏渲染时间的方案](https://junyixie.github.io/2018/02/01/RunloopDetermineFirstRenderedTime/)

既然在 `didFinishLaunchingWithOptions` 所在runloop的末尾，会主动调用CA::Transaction::commit完成视图的渲染, 那么，可以找一个恰当的时机插入我们的代码，来记录当时的时间。
didFinishLaunchingWithOptions 和 viewDidAppear 等一系列方法的执行都是 source0 事件，当source0事件执行完毕后去执行source1事件（如果有），timer 事件属于source1事件源。

根据runloop的内部逻辑，我们可以插入一个timer事件源，在处理完source0后会去执行我们的timer事件。此时记录时间是相当准确的。

```c
2018-02-21 21:17:48.991167+0800 AppStartTime_Example[25922:3193890] BeforeTimers
2018-02-21 21:17:48.991262+0800 AppStartTime_Example[25922:3193890] BeforeSources
2018-02-21 21:17:49.046089+0800 AppStartTime_Example[25922:3193890] didFinishLaunchingWithOptions
2018-02-21 21:17:49.055713+0800 AppStartTime_Example[25922:3193890] viewdidload
2018-02-21 21:17:49.062093+0800 AppStartTime_Example[25922:3193890] didlayoutsubviews
2018-02-21 21:17:49.062508+0800 AppStartTime_Example[25922:3193890] draw rect
2018-02-21 21:17:49.064032+0800 AppStartTime_Example[25922:3193890] viewDidAppear
2018-02-21 21:17:49.064291+0800 AppStartTime_Example[25922:3193890] AppstartTime 首屏渲染记录
2018-02-21 21:17:49.064917+0800 AppStartTime_Example[25922:3193890] BeforeTimers
2018-02-21 21:17:49.065049+0800 AppStartTime_Example[25922:3193890] BeforeSources
```

时间的误差就被锁定在一个runloop之内了。

## Author

junyixie, xiejunyi19970518@outlook.com


## Some Code Reference 
[Joy_HookLoad](https://github.com/joy0304/Joy-Demo/tree/master/HookLoad)

[everettjf_HookCppInitilizers](https://github.com/everettjf/Yolo/tree/master/HookCppInitilizers)
## License

AppStartTime is available under the MIT license. See the LICENSE file for more info.
