//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Temperature: NSObject {
    var timeStamp: Int = 0
    var open: Double?
    var high: Double?
    var low: Double?
    var close: Double?
    
    override init() {
        super.init()
    }
    
    convenience init(timeStamp: Int) {
        self.init()
        self.timeStamp = timeStamp
    }
    
    convenience init(timeStamp: Int, value: Double) {
        self.init(timeStamp: timeStamp)
        open = value
        high = value
        low = value
        close = value
    }
}
