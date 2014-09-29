
//  Created by billsong on 14-9-10.
//  Copyright (c) 2014年 hongDing. All rights reserved.
//

class Util: NSObject {
    
    class func lowestTemperature () ->Float {
        if let lowestTemperature: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("lowestTemperature") {
            
        }
        else {
            setLowestTemperature(36.0)
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("lowestTemperature") as Float
    }
    
    class func setLowestTemperature(currentLowestTemperature:Float) {
         NSUserDefaults.standardUserDefaults().setObject(currentLowestTemperature, forKey: "lowestTemperature")
    }
    
    class func HighestTemperature() ->Float {
        if let highestTemperature: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("highestTemperature") {
            
        }
        else {
            setHighestTemperature(38.0)
        }

        return NSUserDefaults.standardUserDefaults().objectForKey("highestTemperature") as Float
    }
    
    class func setHighestTemperature(currentHighestTemperature:Float) {
       NSUserDefaults.standardUserDefaults().setObject(currentHighestTemperature, forKey: "highestTemperature")
    }
    
    //低温报警
    class func isLowTNotice() ->Bool {
        
        if let isNoticeFlag: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("isLowTNotice") {
        }
        else {
            setIsLowTNotice(false)
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("isLowTNotice") as Bool
    }
    
    class func setIsLowTNotice(isNotice: Bool) {
        NSUserDefaults.standardUserDefaults().setObject(isNotice, forKey: "isLowTNotice")
    }
    
    //高温报警
    class func isHighTNotice() ->Bool {
        
        if let isNoticeFlag: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("isHighTNotice") {
        }
        else {
            setIsHighTNotice(true)
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("isHighTNotice") as Bool
    }
    
    class func setIsHighTNotice(isNotice: Bool) {
        NSUserDefaults.standardUserDefaults().setObject(isNotice, forKey: "isHighTNotice")
    }
    
    /** 十六进制RGB color*/
    class func ColorFromRGB(rgbValue: Int) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0xFF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0xFF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }

    /*
    + (BOOL)writeToLocalForDate:(NSDate *)date
    {
    BOOL isSuccess = NO;
    NSMutableArray *arrM = [OliveDBDao queryHistoryWithDay:date];
    NSString *stringM = [[NSString alloc]init];
    for (Temperature *temper in arrM) {
    NSString *str = [NSString stringWithFormat:@"[%@,%@],\n",temper.cDate,temper.cTemperature];
    stringM = [stringM stringByAppendingString:str];
    }
    if (stringM.length > 0)
    {
    stringM = [stringM stringByReplacingOccurrencesOfString:@"," withString:@""options:NSBackwardsSearch range:NSMakeRange(stringM.length-2, 2)];
    stringM = [stringM stringByReplacingOccurrencesOfString:@"\n" withString:@""options:NSBackwardsSearch range:NSMakeRange(stringM.length-1, 1)];
    NSString *content = [NSString stringWithFormat:@"[%@]",stringM];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"data.json"];
    if (![fileManager fileExistsAtPath:writableDBPath]) {
    BOOL bo = [fileManager createFileAtPath:writableDBPath contents:[content  dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    isSuccess = bo;
    }
    else {
    BOOL bo = [content writeToFile:writableDBPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    isSuccess = bo;
    }
    }
    else
    {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:[DateUtil stringFromDate:date withFormat:@"yyyy-MM-dd"] message:@"暂无历史数据" delegate:nil cancelButtonTitle:@"好" otherButtonTitles:nil, nil];
    [alert show];
    NSLog(@"暂无历史记录");
    }
    return isSuccess;
    }
    */
    
    
    
    
    //test data
//    
//    var arr1: Array<Int> = [1]
//    var arr2: Array<Int> = [1, 2]
//    var arr3: Array<Int> = [1, 2, 3, 4, 5]
//    var arr4: Array<Int> = [1, 2, 3, 4, 5, 6]
//    var arr5: Array<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9]
//    var arr6: Array<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
//    var arr7: Array<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
//    var arr8: Array<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
//    var arr9: Array<Int> = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
//    var arr10: Array<Int> =  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
//    var arr11: Array<Int> =  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
//    var arr12: Array<Int> =  [33.10,33.12,33.68,36,37,38,36,37,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,37,33,38,38,37,37,36,38,39]
//    var arr13: Array<Int> = Array(count: 100, repeatedValue: 0)
//    
//    func testOB() {
//        //            for var i = 0 ; i < 100 ; i++ {
//        //                arr13[i] = 100 - i
//        //                if i%3 == 0 {
//        //                    arr13[i] += 10
//        //                }
//        //                if i%4 == 0 {
//        //                    arr13[i] -= 20
//        //                }
//        //            }
//        for (index, element) in enumerate(arr11) {
//            var temper: Temperature = Temperature()
//            temper.cTemperature = NSString(format: "%.2f", Float(element))
//            var i: NSTimeInterval = NSTimeInterval(index)
//            var date = NSDate(timeInterval: -(24*3600*1 + i), sinceDate: NSDate.date())
//            temper.cDate = DateUtil.timestampFromDate(date)
//            OliveDBDao.saveTemperature(temper)
//            
//        }
//    }
//    
    
}
