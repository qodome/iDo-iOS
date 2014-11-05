//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Util: NSObject {
    
    class func lowestTemperature () ->Float {
        if let lowestTemperature: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("lowestTemperature") {
            
        } else {
            setLowestTemperature(36.0)
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("lowestTemperature") as Float
    }
    
    class func setLowestTemperature(currentLowestTemperature:Float) {
        NSUserDefaults.standardUserDefaults().setObject(currentLowestTemperature, forKey: "lowestTemperature")
    }
    
    class func HighestTemperature() ->Float {
        if let highestTemperature: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("highestTemperature") {
            
        } else {
            setHighestTemperature(38.0)
        }
        
        return NSUserDefaults.standardUserDefaults().objectForKey("highestTemperature") as Float
    }
    
    class func setHighestTemperature(currentHighestTemperature:Float) {
        NSUserDefaults.standardUserDefaults().setObject(currentHighestTemperature, forKey: "highestTemperature")
    }
    
    // 低温报警
    class func isLowTNotice() ->Bool {
        if let isNoticeFlag: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("isLowTNotice") {
        } else {
            setIsLowTNotice(false)
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("isLowTNotice") as Bool
    }
    
    class func setIsLowTNotice(isNotice: Bool) {
        NSUserDefaults.standardUserDefaults().setObject(isNotice, forKey: "isLowTNotice")
    }
    
    // 高温报警
    class func isHighTNotice() ->Bool {
        if let isNoticeFlag: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("isHighTNotice") {
        } else {
            setIsHighTNotice(true)
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("isHighTNotice") as Bool
    }
    
    class func setIsHighTNotice(isNotice: Bool) {
        NSUserDefaults.standardUserDefaults().setObject(isNotice, forKey: "isHighTNotice")
    }
}
