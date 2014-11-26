//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DateUtils: NSObject {
    
    // NSString 转换成 NSdate
    class func dateFromString(dateStr: NSString, withFormat format: NSString) -> NSDate {
        var dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.dateFromString(dateStr)!
    }
    
    // NSString 转换成 时间戳
    class func timestampFromDate(date: NSDate) -> NSString {
        let currentTimeMillis = date.timeIntervalSince1970 * 1000
        return "\(currentTimeMillis)"
    }
    
    //NSDate 转换成 NSString
    class func stringFromDate(date: NSDate, WithFormat format:NSString) -> NSString {
        var dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.stringFromDate(date)
    }
    
    //NSString 转换成 时间字符串
    class func getTimeWithStamp(timeStamp: NSString, withFormat format: NSString) -> NSString {
        let date: NSDate = NSDate(timeIntervalSince1970: (timeStamp.doubleValue) / 1000)
        var fm: NSDateFormatter = NSDateFormatter()
        fm.dateFormat = format
        return fm.stringFromDate(date)
    }
}
