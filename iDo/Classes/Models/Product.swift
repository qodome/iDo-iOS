//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class Product: BaseModel {
    var id: NSNumber!
    var created: NSDate!
    var title: NSString = ""
    var summary: NSString = ""
    var tags: NSString = ""
    var name: NSString = ""
    var color: NSString = ""
    
    override class func getMapping() -> Dictionary<String, String> {
        return [
            "id" : "id",
            "created" : "created",
            "title" : "title",
            "summary" : "summary",
            "tags" : "tags",
            "name" : "name",
            "color" : "color"
        ]
    }
}
