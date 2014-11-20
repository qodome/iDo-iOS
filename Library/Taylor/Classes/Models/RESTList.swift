//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class RESTList: NSObject {
    var count: NSNumber!
    var next: String?
    var previous: String?
    var results = []
    
    class func getMapping() -> NSDictionary {
        return [
            "count" : "count",
            "next" : "next",
            "previous" : "previous"
        ]
    }
}
