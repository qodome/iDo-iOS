//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Util: NSObject {
    
    class func lowTemperature() -> Float {
        if NSUserDefaults.standardUserDefaults().objectForKey("lowestTemperature") == nil {
            setLowTemperature(36.0)
        }
        return NSUserDefaults.standardUserDefaults().floatForKey("lowestTemperature")
    }
    
    class func setLowTemperature(value: Float) {
        NSUserDefaults.standardUserDefaults().setFloat(value, forKey: "lowestTemperature")
    }
    
    class func HighTemperature() -> Float {
        if NSUserDefaults.standardUserDefaults().objectForKey("highestTemperature") == nil {
            setHighTemperature(38.0)
        }
        return NSUserDefaults.standardUserDefaults().floatForKey("highestTemperature")
    }
    
    class func setHighTemperature(value: Float) {
        NSUserDefaults.standardUserDefaults().setFloat(value, forKey: "highestTemperature")
    }
    
    // 低温报警
    class func isLowTNotice() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("notification_low")
    }
    
    class func setIsLowTNotice(isNotice: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(isNotice, forKey: "notification_low")
    }
    
    // 高温报警
    class func isHighTNotice() -> Bool {
        if NSUserDefaults.standardUserDefaults().objectForKey("notification_high") == nil {
            setIsHighTNotice(true)
        }
        return NSUserDefaults.standardUserDefaults().boolForKey("notification_high")
    }
    
    class func setIsHighTNotice(isNotice: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(isNotice, forKey: "notification_high")
    }
}
