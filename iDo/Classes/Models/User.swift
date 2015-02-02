//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class User: BaseUser {
    //    var likes: [Like] = [] // 手动补
    //    var votes: [Vote] = [] // 手动补
    var tags: NSString = ""
    var sign: NSString = ""
    var likesCount: NSNumber = 0 // TODO: 修改用户的信息的时候会不会一起改掉
    var commentsCount: NSNumber = 0
    
    override class func getMapping() -> [String : String] {
        var dict = super.getMapping()
        //        let d = [
        //            "tags" : "tags",
        //            "sign" : "sign",
        //            "likes_count" : "likesCount",
        //            "comments_count" : "commentsCount",
        //        ]
        dict["taqs"] = "tags"
        dict["sign"] = "sign"
        dict["likes_count"] = "likesCount"
        dict["comments_count"] = "commentsCount"
        return dict
    }
}
