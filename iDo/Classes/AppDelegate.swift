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
        lowAlert = Settings.isLowTNotice()
        highAlert = Settings.isHighTNotice()
        isFahrenheit = Settings.isFahrenheit()
        if UIApplication.instancesRespondToSelector("registerUserNotificationSettings:") {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil))
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
        let manager = BLEManager.sharedManager()
        for peripheral in manager.peripherals {
            manager.central.cancelPeripheralConnection(peripheral)
        }
        manager.peripherals.removeAll(keepCapacity: false)
    }
}
