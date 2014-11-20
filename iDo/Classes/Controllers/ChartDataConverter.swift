//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class ChartDataConverter: UIView {
    var inputData: NSMutableArray = NSMutableArray()
    var pointNumberInSection: Int = 0
    
    func convertDataForToday(inputData: NSMutableArray) ->([Int : CGFloat], [String]) {
        var outPutData:[Int : CGFloat] = Dictionary()
        var titleStringArrForXAXis:[String] = []
        var currentDate = DateUtils.stringFromDate(NSDate(), WithFormat: "yyyy-MM-dd HH:mm:ss") as NSString
        var currentHour = (((currentDate.substringFromIndex(11) as NSString).substringWithRange(NSRange(location: 0, length: 2))) as NSString).intValue
        //生成x轴的title
        for var j = 3; j >= -1; j-- {
            titleStringArrForXAXis.append("\(currentHour - j)时")
        }
        for number in inputData {
            let mTemperature = number as Temperature
            var date = DateUtils.getTimeWithStamp((number as Temperature).timeStamp, withFormat: "yyyy-MM-dd HH:mm:ss")
            var timeOnAday = date.substringFromIndex(11) as NSString
            var hour = (timeOnAday.substringWithRange(NSRange(location: 0, length: 2)) as NSString).intValue
            var minute = (timeOnAday.substringWithRange(NSRange(location: 3, length: 2)) as NSString).intValue
            var second = (timeOnAday.substringWithRange(NSRange(location: 6, length: 2)) as NSString).intValue
            if hour >= (currentHour - 3) { // 显示最近4个小时的数据
                var currrentNumber = Int((hour - currentHour + 3) * 120 + minute * 2 + second / 30)
                outPutData[currrentNumber] = CGFloat((mTemperature.high as NSString).floatValue)
            }
        }
        return (outPutData, titleStringArrForXAXis)
    }
    
    func convertDataForHistory(inputData: NSMutableArray) ->([Int : CGFloat], [String]) {
        var outPutData:[Int : CGFloat] = Dictionary()
        var titleStringArrForXAXis:[String] = []
        //生成x轴的title
        for i in 0..<24 {
            titleStringArrForXAXis.append("\(i)时")
        }
        for number in inputData {
            let mTemperature = number as Temperature
            var date = DateUtils.getTimeWithStamp((number as Temperature).timeStamp, withFormat: "yyyy-MM-dd HH:mm:ss")
            var timeOnAday = date.substringFromIndex(11) as NSString
            var hour = (timeOnAday.substringWithRange(NSRange(location: 0, length: 2)) as NSString).intValue
            var minute = (timeOnAday.substringWithRange(NSRange(location: 3, length: 2)) as NSString).intValue
            var second = (timeOnAday.substringWithRange(NSRange(location: 6, length: 2)) as NSString).intValue
            var currrentNumber = Int(hour * 12 + minute / 5)
            outPutData[currrentNumber] = CGFloat((mTemperature.high as NSString).floatValue)
        }
        return (outPutData, titleStringArrForXAXis)
    }
}
