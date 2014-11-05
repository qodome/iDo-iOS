//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Temperature: NSObject {
    
    var cDate: NSString!
    var cTemperature: NSString!
    
    override init() {
    }
    
    init(coder aDecoder: NSCoder!) {
        super.init()
        if aDecoder != nil {
            cDate = aDecoder.decodeObjectForKey("cDate") as String
            cTemperature = aDecoder.decodeObjectForKey("cTemperature") as String
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder!) {
        aCoder.encodeObject(cDate, forKey: "cDate")
        aCoder.encodeObject(cTemperature, forKey: "cTemperature")
    }
}
