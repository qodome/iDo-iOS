//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class Firmware: BaseModel {
    var modelNumber: NSString = ""
    var downloadUrl: NSString = ""
    var updated: NSDate!
    var revision: NSString = ""
    var size: NSNumber!
    var product: Product?
    
    override class func getMapping() -> [String : String] {
        return [
            "model_number" : "modelNumber",
            "download_url" : "downloadUrl",
            "updated" : "updated",
            "revision" : "revision",
            "size" : "size"
        ]
    }
}
