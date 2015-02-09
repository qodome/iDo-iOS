#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <HealthKit/HealthKit.h>

// BEMSimpleLineGraphView https://github.com/Boris-Em/BEMSimpleLineGraph
#import "BEMSimpleLineGraphView.h"

// Facebook https://developers.facebook.com/docs/ios/

// FormatterKit https://github.com/mattt/FormatterKit
#import <FormatterKit/TTTTimeIntervalFormatter.h>

// JTCalendar https://github.com/jonathantribouharet/JTCalendar
#import "JTCalendar.h"

// M13ProgressSuite https://github.com/Marxon13/M13ProgressSuite
#import <M13ProgressSuite/M13ProgressHUD.h>
#import <M13ProgressSuite/M13ProgressViewRing.h>
#import <M13ProgressSuite/M13ProgressViewPie.h>
#import <M13ProgressSuite/UINavigationController+M13ProgressViewBar.h>

// RestKit https://github.com/RestKit/RestKit
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreServices/CoreServices.h>
#endif

#import <RestKit/RestKit.h>

// SDWebImage https://github.com/rs/SDWebImage
#import <SDWebImage/UIImageView+WebCache.h>

// TLYShyNavBar https://github.com/telly/TLYShyNavBar
#import <TLYShyNavBar/TLYShyNavBarManager.h>

// WeiboSDK https://github.com/sinaweibosdk/weibo_ios_sdk/
#import <WeiboSDK/WeiboSDK.h>

// Weixin https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list
#import <Weixin/WXApi.h>

#ifndef __OPTIMIZE__
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) {}
#endif
