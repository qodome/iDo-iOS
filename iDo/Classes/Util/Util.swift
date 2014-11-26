//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Util: NSObject {
    
    class func lowTemperature() -> Float {
        if let lowestTemperature: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("lowestTemperature") {
            
        } else {
            setLowTemperature(36.0)
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("lowestTemperature") as Float
    }
    
    class func setLowTemperature(currentLowestTemperature: Float) {
        NSUserDefaults.standardUserDefaults().setObject(currentLowestTemperature, forKey: "lowestTemperature")
    }
    
    class func HighTemperature() -> Float {
        if let highestTemperature: AnyObject = NSUserDefaults.standardUserDefaults().objectForKey("highestTemperature") {
            
        } else {
            setHighTemperature(38.0)
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("highestTemperature") as Float
    }
    
    class func setHighTemperature(currentHighestTemperature:Float) {
        NSUserDefaults.standardUserDefaults().setObject(currentHighestTemperature, forKey: "highestTemperature")
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
        return NSUserDefaults.standardUserDefaults().boolForKey("notification_high")
    }
    
    class func setIsHighTNotice(isNotice: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(isNotice, forKey: "notification_high")
    }
}
