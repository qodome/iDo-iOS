//
//  Copyright (c) 2014年 NY. All rights reserved.
//

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        setTheme()
        window?.backgroundColor = UIColor.whiteColor()
        RKObjectManager.setSharedManager(RKObjectManager(baseURL: NSURL(string: BASE_URL)))
        RKObjectManager.sharedManager().HTTPClient.setDefaultHeader("Accept-Encoding", value: "gzip, deflate")
        // Settings
        initSettings()
        if UIApplication.instancesRespondToSelector("registerUserNotificationSettings:") {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil))
        }
        // HealthKit
        if iOS8() {
            if HKHealthStore.isHealthDataAvailable() {
                let store = HKHealthStore()
                // 1. Set the types you want to read from HK Store
                let readTypes = NSSet(array: [
                    HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth), // 生日
                    HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex) //性别
                    HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType), // 血型
                    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight), // 身高
                    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass), // 体重
                    ])
                // 2. Set the types you want to write to HK Store
                let shareTypes = NSSet(array:[
                    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature),
                    ])
                // 4.  Request HealthKit authorization
                store.requestAuthorizationToShareTypes(shareTypes, readTypes: readTypes, completion: {(succeeded: Bool, error: NSError!) in
                    if succeeded && error == nil {
                        println("Successfully received authorization")
                    } else {
                        println(error)
                    }
                })
            }
        }
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        application.cancelAllLocalNotifications()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        println("applicationWillTerminate")
        application.applicationIconBadgeNumber = 0
        application.cancelAllLocalNotifications()
        let manager = BLEManager.sharedManager
        for peripheral in manager.peripherals {
            manager.central.cancelPeripheralConnection(peripheral)
        }
        manager.peripherals.removeAll(keepCapacity: false)
    }
}
