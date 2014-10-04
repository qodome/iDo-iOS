//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DBManager: NSObject {

    struct FMDatabaseSingleton {
        static var predicate:dispatch_once_t = 0
        static var instance:FMDatabase? = nil
    }
    
    override init() {
        super.init()
    }
    
    class func kDataBasePath() -> String {
        let kDataBaseName = "OliveDB.sqlite"
        var path: String = "\(NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0].stringByAppendingPathComponent(kDataBaseName))"
        return path
    }
    
    //数据库对象单例方法
    class func sharedDataBase() -> FMDatabase {
//        struct FMDatabaseSingleton {
//            static var predicate:dispatch_once_t = 0
//            static var instance:FMDatabase? = nil
//        }
        dispatch_once(&FMDatabaseSingleton.predicate,{
            FMDatabaseSingleton.instance = FMDatabase(path: DBManager.kDataBasePath())
            println("instance")
        })
        return FMDatabaseSingleton.instance!
    }
    
    //关闭数据库
    class func closeDataBase() {
        if !FMDatabaseSingleton.instance!.close() {
            println("数据库关闭异常，请检查")
            return
        }
    }
    
    //清空数据库内容
    class func deleteDataBase() -> Bool {
        var isSuccess = false
        if (FMDatabaseSingleton.instance != nil) {
            var error: NSError?
            var fileManager: NSFileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(DBManager.kDataBasePath()) {
                sharedDataBase().close()
                isSuccess = fileManager.removeItemAtPath(DBManager.kDataBasePath(), error: &error)
                if !isSuccess {
                    //fatalError("Failed to delete old database file with message")
                    println("Failed to delete old database file with message")
                } else {
                    isSuccess = true
                    println("删除成功")
                }
            }
        }
        return isSuccess
    }
    
    //创建所有表
    class func createTable() -> Bool {
        println("\(DBManager.kDataBasePath())")
        if(true) {
            var shareDataBase: FMDatabase = DBManager.sharedDataBase()
            if sharedDataBase().open() {
                if !DBManager.isTableExist("downLoad_table") {
                    let sql = "CREATE TABLE \"downLoad_table\" (\"newsType\" TEXT check(typeof(\"newsType\") = 'text') , \"att\" BLOB)"
                    shareDataBase.executeUpdate(sql, withArgumentsInArray: nil)
                }
                shareDataBase.close()
            }
        }
        return true
    }
    
    
    //判断表是否存在
    class func isTableExist(tableName:String) -> Bool {
        var shareDataBase: FMDatabase = DBManager.sharedDataBase()
        if shareDataBase.open() {
            let rs = shareDataBase.executeQuery("select count(*) as 'count' from sqlite_master where type ='table' and name = ?", withArgumentsInArray: [tableName])?
            while ((rs?.next()) != nil) {
                let count = rs?.intForColumn("count")
                if count == 0 {
                    return false
                } else {
                    return true
                }
            }
        }
        return false
    }
    
}
