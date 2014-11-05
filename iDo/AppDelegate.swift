//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        application.applicationIconBadgeNumber = 0
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(application: UIApplication) {
        println("applicationWillTerminate")
        let manager = BLEManager.sharedManager()
        for i in 0..<manager.connected.count {
            manager.central.cancelPeripheralConnection(manager.connected[i])
            manager.connected.removeAtIndex(i)
        }
        for i in 0..<manager.devices.count {
            manager.central.cancelPeripheralConnection(manager.devices[i])
            manager.devices.removeAtIndex(i)
        }
    }
}
