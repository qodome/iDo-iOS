//
//  AppDelegate.swift
//  Olive-ios
//
//  Created by billsong on 14-9-5.
//  Copyright (c) 2014年 hongDing. All rights reserved.
//

import UIKit

import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        application.applicationIconBadgeNumber = 0
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(application: UIApplication) {
        println("applicationWillTerminate")
        var devicesCentralManager =  DeviceCentralManager.instanceForCenterManager()
        for var i=0;i < devicesCentralManager.devicesArrayOnSelectedStatus.count;i++ {
            var mPeripheral:CBPeripheral = devicesCentralManager.devicesArrayOnSelectedStatus[i] as CBPeripheral
            devicesCentralManager.devicesCentralManager.cancelPeripheralConnection(mPeripheral)
            devicesCentralManager.devicesArrayOnSelectedStatus.removeObject(mPeripheral)
        }
        
        for var i=0;i < devicesCentralManager.devicesArrayOnNoSelectedStatus.count;i++ {
            var mPeripheral:CBPeripheral = devicesCentralManager.devicesArrayOnNoSelectedStatus[i] as CBPeripheral
            devicesCentralManager.devicesCentralManager.cancelPeripheralConnection(mPeripheral)
            devicesCentralManager.devicesArrayOnNoSelectedStatus.removeObject(mPeripheral)
        }
    }
    
}
