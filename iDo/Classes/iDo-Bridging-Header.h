#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
//#import <HealthKit/HealthKit.h>

// BEMSimpleLineGraphView
#import "BEMSimpleLineGraphView.h"

// FormatterKit
#import <FormatterKit/TTTTimeIntervalFormatter.h>

// JTCalendar
#import "JTCalendar.h"

// M13ProgressSuite
#import <M13ProgressSuite/M13ProgressViewRing.h>
#import <M13ProgressSuite/M13ProgressViewPie.h>

// RestKit
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreServices/CoreServices.h>
#endif

#import <RestKit/RestKit.h>

// SDWebImage
#import <SDWebImage/UIImageView+WebCache.h>

#ifndef __OPTIMIZE__
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) {}
#endif
