//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Temperature: NSObject {
    var timeStamp: Int = 0
    var open: Float?
    var high: Float?
    var low: Float?
    var close: Float?
    
    override init() {
        super.init()
    }
    
    convenience init(timeStamp: Int) {
        self.init()
        self.timeStamp = timeStamp
    }
    
    convenience init(timeStamp: Int, value: Float) {
        self.init(timeStamp: timeStamp)
        open = value
        high = value
        low = value
        close = value
    }
}
