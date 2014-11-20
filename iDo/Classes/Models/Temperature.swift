//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Temperature: NSObject {
    
    var timeStamp: NSString!
    var high: NSString!
    
    override init() {
    }
    
    init(coder aDecoder: NSCoder!) {
        super.init()
        if aDecoder != nil {
            timeStamp = aDecoder.decodeObjectForKey("time_stamp") as String
            high = aDecoder.decodeObjectForKey("high") as String
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder!) {
        aCoder.encodeObject(timeStamp, forKey: "time_stamp")
        aCoder.encodeObject(high, forKey: "high")
    }
}
