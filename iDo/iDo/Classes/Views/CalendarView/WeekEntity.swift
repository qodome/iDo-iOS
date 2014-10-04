//
//  Copyright (c) 2014年 NY. All rights reserved.
//

enum WeekType: Int{
    case Sunday = 1  //周日
    case Monday //周一
    case Tuesday //周二
    case Wednesday //周三
    case Thursday //周四
    case Friday //周五
    case Saturday //周六
}

class WeekEntity: NSObject {
    
    var weektype: WeekType!
    var weekDate: String!
    var subtitule: String!
    
    override init(){
        
    }
}
