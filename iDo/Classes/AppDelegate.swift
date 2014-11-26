//
//  Copyright (c) 2014年 NY. All rights reserved.
//

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        if UIApplication.instancesRespondToSelector("registerUserNotificationSettings:") {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: nil))
        }
        // application.applicationIconBadgeNumber = 0
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(application: UIApplication) {
        println("applicationWillTerminate")
        let manager = BLEManager.sharedManager()
        manager.central.cancelPeripheralConnection(manager.connected)
        for peripheral in manager.peripherals {
            manager.central.cancelPeripheralConnection(peripheral)
        }
        manager.peripherals.removeAll(keepCapacity: false)
    }
}
