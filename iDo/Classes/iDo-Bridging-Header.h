#import <UIKit/UIKit.h>

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

// BEMSimpleLineGraphView
#import "BEMSimpleLineGraphView.h"

// JTCalendar
#import "JTCalendar.h"

#ifndef __OPTIMIZE__
#define NSLog(...) NSLog(__VA_ARGS__)
#else
#define NSLog(...) {}
#endif
