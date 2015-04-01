//
//  Copyright (c) 2014年 NY. All rights reserved.
//

@UIApplicationMain
class AppDelegate: BaseAppDelegate {
    
    // MARK: - 🐤 继承 Taylor
    override func onFinishLaunching(application: UIApplication, options: [NSObject : AnyObject]?) {
        super.onFinishLaunching(application, options: options)
        // Settings
        initSettings()
        // 注册通知
        if UIApplication.instancesRespondToSelector("registerUserNotificationSettings:") {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil))
        }
        // HealthKit
        if iOS8() {
            if HKHealthStore.isHealthDataAvailable() {
                canHealthKit = true
                let readTypes = NSSet(array: [ // HK读权限
                    HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth), // 生日
                    HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex), //性别
                    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight), // 身高
                    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass), // 体重
                    HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType) // 血型
                    ])
                let shareTypes = NSSet(array: [ // HK写权限
                    HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyTemperature)
                    ])
                let store = HKHealthStore()
                store.requestAuthorizationToShareTypes(shareTypes, readTypes: readTypes, completion: { (success, error) in
                    if !success {
                        Log(error.localizedDescription)
                    }
                })
            }
            let store = HKHealthStore()
            var error: NSError?
            let birthDay = store.dateOfBirthWithError(&error) // 生日
            let biologicalSex = store.biologicalSexWithError(&error) //性别
            let bloodType = store.bloodTypeWithError(&error) // 血型
        }
    }
    
    // MARK: - 💖 生命周期 (Lifecyle)
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
