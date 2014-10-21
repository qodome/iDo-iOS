//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class OliveDBDao: NSObject {
    //类属性不能加class 所以用结构体来保持静态对象
    struct OliveDBDaoSingleton {
        //温度表的表名
        static let sTableName: String = "OliveTable"
    }
    
    //创建温度表
    class func createTable() -> Bool {
        var result = false
        let shareDataBase: FMDatabase = DBManager.sharedDataBase()
        if shareDataBase.open() {
            if !DBManager.isTableExist(OliveDBDaoSingleton.sTableName) {
                let sql = "CREATE TABLE \(OliveDBDaoSingleton.sTableName)(temperature BLOB, cDate DATE)"
                result = shareDataBase.executeUpdate(sql, withArgumentsInArray: nil)
            } else {
                result = true
            }
            shareDataBase.close()
        }
        return result
        
    }
    
    class func saveTemperature(temper:Temperature) -> Bool {
        var isOK = false
        if createTable() {
            deleteHistoryWithDay(NSDate())
            let share: FMDatabase = DBManager.sharedDataBase()
            if share.open() {
                let dateStr: String  = DateUtil.getTimeWithStamp(temper.cDate, withFormat:"yyyy-MM-dd HH:mm:ss" )
                let sql = "INSERT INTO \(OliveDBDaoSingleton.sTableName) (temperature,cDate) VALUES(?,?)"
                isOK = share.executeUpdate(sql, withArgumentsInArray: [NSKeyedArchiver.archivedDataWithRootObject(temper),dateStr])
                share.close()
            }
        } else {
            isOK = false
        }
        return isOK
    }
    
    class func queryHistoryWithDay(date:NSDate) -> NSMutableArray {
        var arr: NSMutableArray = NSMutableArray()
        if createTable() {
            let share: FMDatabase = DBManager.sharedDataBase()
            if share.open() {
                let beginDateStr = DateUtil.stringFromDate(date, WithFormat: "yyyy-MM-dd 00:00:00")
                let endDateStr = DateUtil.stringFromDate(date, WithFormat: "yyyy-MM-dd 23:59:59")
                let sql = "SELECT * FROM \(OliveDBDaoSingleton.sTableName) WHERE cDate BETWEEN ? AND ?"
                let rs: FMResultSet = share.executeQuery(sql, withArgumentsInArray: [beginDateStr,endDateStr])
                while (rs.next()) {
                    let tempData: NSData = rs.dataForColumn("temperature")
                    let temp: Temperature = NSKeyedUnarchiver.unarchiveObjectWithData(tempData) as Temperature
                    arr.addObject(temp)
                }
                share.close()
            }
        }
        return arr
    }
    
    class func deleteHistoryWithDay(date:NSDate) -> Bool {
        var isSuccess = false
        if createTable() {
            let share: FMDatabase = DBManager.sharedDataBase()
            if share.open() {
                let secondsPerDay = (NSTimeInterval)(24 * 60 * 60 * 31)
                let preDate = date.dateByAddingTimeInterval(-secondsPerDay)
                let beginDateStr = DateUtil.stringFromDate(preDate, WithFormat: "yyyy-MM-dd 00:00:00")
                let endDateStr = DateUtil.stringFromDate(preDate, WithFormat: "yyyy-MM-dd 23:59:59")
                let sql = "DELETE FROM \(OliveDBDaoSingleton.sTableName) WHERE cDate BETWEEN ? AND ?"
                isSuccess = share.executeUpdate(sql, withArgumentsInArray: [beginDateStr,endDateStr])
                share.close()
            }
        }
        return isSuccess
    }
    
}
