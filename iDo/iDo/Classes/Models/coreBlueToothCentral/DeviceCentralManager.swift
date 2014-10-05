//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

//优化

protocol DeviceCentralManagerDidStartsendDataDelegate {
    func  deviceCentralManagerDidStartsendData()
}

protocol DeviceCentralManagerdidUpdateValueToCharacterisrticDelegate {
   func didUpdateValueToCharacteristic(characteristic: CBCharacteristic?, cError error: NSError?)
}

protocol DeviceCentralManagerdidChangedCurrentConnectedDeviceDelegate { // TODO: 重命名
    func centralss(centeral: CBCentralManager, unConnectedDevices unConnectedDeviceArr: NSArray, connectedDevices connectedDeviceArr: NSArray)
}

class DeviceCentralManager: NSObject {

    let kServiceUUID:String = "1809" // Health Thermometer
    let kCharacteristicUUID = "2A1C" // Temperature Measurement

    var isShowAllCanConnectedDevices: Bool = false // 只有在用户点击刷新设备button后或者第一次进入app才为true
//    var isUserCancelConnectingDevices: Bool = false // 用户手动取消连接是为true TODO: 是否有用
    var isPeripheralTryToConnect: Bool = false
    var isScanning: Bool = false // 只有在用户点击刷新设备button后或者第一次进入app才为true
    var devicesArrayOnSelectedStatus: NSMutableArray! //放置已经连接的peripheral
    var devices: [CBPeripheral] = [] // 放置可连接的(但未连接的)peripherals
//    var devicesArray: NSMutableArray! // 保持指向peripherals的引用,不然会peripheras会丢失

    var startSendingDataDelegate: DeviceCentralManagerDidStartsendDataDelegate? // 
    var characteristicDelegate: DeviceCentralManagerdidUpdateValueToCharacterisrticDelegate? //温度数据发送 代理
    var delegate: DeviceCentralManagerdidChangedCurrentConnectedDeviceDelegate? //设备data变化 代理
    var central: CBCentralManager!
    var currentPeripheral: CBPeripheral!

    // MARK: - 生命周期 (Lifecyle)
    class func instanceForCenterManager()->DeviceCentralManager {
        struct DeviceCentralSingleton{
            static var predicate:dispatch_once_t = 0
            static var instance:DeviceCentralManager? = nil
        }
        dispatch_once(&DeviceCentralSingleton.predicate,{
            DeviceCentralSingleton.instance = DeviceCentralManager()
            println("instance")
        })
        return DeviceCentralSingleton.instance!
    }

    override init() {
        super.init()
        println("devicesInit")
        central = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey:NSNumber.numberWithBool(true)])
//        devicesArray = NSMutableArray()
        devicesArrayOnSelectedStatus = NSMutableArray()
    }

    func userConnectPeripheral(index: Int) {
        var peripheral = devices[index] as CBPeripheral
        let lastPeripheral: CBPeripheral? = devicesArrayOnSelectedStatus.lastObject as? CBPeripheral
        if lastPeripheral != nil {
            unbind(lastPeripheral)
        }
        bind(peripheral)
        central.connectPeripheral(peripheral, options: nil) // 连接
        devices.removeAtIndex(index)
        
        isPeripheralTryToConnect = true
        ////
        delegate?.centralss(central, unConnectedDevices: devices, connectedDevices: devicesArrayOnSelectedStatus)
    }

    /** 绑定设备 */
    func bind(peripheral:CBPeripheral!) {
        NSLog("    绑定设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
        setConnectingPeripheralUUID(peripheral.identifier.UUIDString)
        if !isShowAllCanConnectedDevices {
            stopScanPeripherals()
        }
        isPeripheralTryToConnect =  true
        if !devicesArrayOnSelectedStatus.containsObject(peripheral) {
            devicesArrayOnSelectedStatus.addObject(peripheral)
        }
    }

    /** 解绑设备 */
    func unbind(peripheral: CBPeripheral!) {
        NSLog("    解绑设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
        setConnectingPeripheralUUID("")
        central.cancelPeripheralConnection(peripheral)
        devicesArrayOnSelectedStatus.removeLastObject()
        if !contains(devices, peripheral) {
            devices.append(peripheral)
        }
        isPeripheralTryToConnect = false
        characteristicDelegate?.didUpdateValueToCharacteristic(nil, cError: nil)
        delegate?.centralss(central, unConnectedDevices: devices, connectedDevices: devicesArrayOnSelectedStatus) // 刷新UI
    }

    func startScanPeripherals() {
        isScanning = true
        central.scanForPeripheralsWithServices([CBUUID.UUIDWithString(kServiceUUID)], options: nil)
    }

    func stopScanPeripherals() {
        central.stopScan()
        isScanning = false
    }

    func disConnectOtherPeripheralAfterBandedAConnectingPeripheral() {
        if devices.count != 0 {
//            for var i = 0; i < devicesArray.count; i++ {
//                var mPeripheral:CBPeripheral = devicesArray[i] as CBPeripheral
//                //////
//                //a != b
//                if self.lastConnectedPeripheralUUID() != mPeripheral.identifier.UUIDString{
//                    central.cancelPeripheralConnection(mPeripheral)
//                    devicesArray.removeObject(mPeripheral)
//                }
//            }
        }
    }

    func lastConnectedPeripheralUUID() -> String {
        if NSUserDefaults.standardUserDefaults().objectForKey("selectedPeripheralId") == nil {
            setConnectingPeripheralUUID("")
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("selectedPeripheralId") as String
    }

    func setConnectingPeripheralUUID(peripheralUUID: String?) {
        return NSUserDefaults.standardUserDefaults().setObject(peripheralUUID, forKey:"selectedPeripheralId")
    }

}

// MARK: - CBCentralManagerDelegate
extension DeviceCentralManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(central: CBCentralManager!) {
        NSLog("💙 蓝牙状态更新: %i", central.state.toRaw())
        switch central.state {
        case CBCentralManagerState.PoweredOn:
            central.scanForPeripheralsWithServices([CBUUID.UUIDWithString(kServiceUUID)], options: nil)
//            central.scanForPeripheralsWithServices([CBUUID.UUIDWithString(kServiceUUID)], options: [CBCentralManagerOptionShowPowerAlertKey: NSNumber.numberWithBool(true)])
        default:
            devicesArrayOnSelectedStatus.removeAllObjects()
            devices.removeAll(keepCapacity: true)
            characteristicDelegate?.didUpdateValueToCharacteristic(nil, cError: nil)
            delegate?.centralss(central, unConnectedDevices: devices, connectedDevices: devicesArrayOnSelectedStatus)
        }
    }

    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        NSLog("💙 发现设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
//        if !devicesArray.containsObject(peripheral) {
//            devicesArray.addObject(peripheral)
//        }
        var peripheralId:String = lastConnectedPeripheralUUID()
        // println("perID-\(peripheralId) currentState:\(peripheral)")
        if isShowAllCanConnectedDevices {
            println("💙 💙 刷新")
            if !contains(devices, peripheral) {
                devices.append(peripheral)
            }
//            central.connectPeripheral(peripheral, options:nil)
        } else if peripheralId == "" {
            //未绑定 连接所有
            println("💙 💙 未绑定")
            if !contains(devices, peripheral) {
                devices.append(peripheral)
            }
//            central.connectPeripheral(peripheral, options:nil)
        } else if peripheralId == peripheral.identifier.UUIDString {
            //有绑定 只试图连接 绑定的设备
            println("💙 💙 绑定")
            bind(peripheral)
            central.connectPeripheral(peripheral, options:nil)
        }
    }

    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("💙 连上设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
        // TODO: 停止scan
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID.UUIDWithString(kServiceUUID)])
    }

    // MARK: - 处理异常
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("💙 断开设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
//        devicesArray.removeObject(peripheral)
        var peripheralId:String = lastConnectedPeripheralUUID()
        println("dis connect pID \(peripheralId)")
    }

    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("💙 连接失败: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
//        devicesArray.removeObject(peripheral)
    }

}

// MARK: - CBPeripheralDelegate
extension DeviceCentralManager: CBPeripheralDelegate {
   
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        println("3-peripheral\(peripheral.identifier) did discover services)")
        if error != nil {
           // devicesArray.removeObject(peripheral)
        } else {
            for var i = 0; i < peripheral.services.count; i++ {
                var service:CBService = peripheral.services[i] as CBService
                if CBUUID.UUIDWithString(kServiceUUID) == service.UUID {
                    peripheral.discoverCharacteristics([CBUUID.UUIDWithString(kCharacteristicUUID)], forService: service)
                    break
                }
            }
        }
    }

    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        println("4-check out characteristics")
        if error != nil {
          //  devicesArray.removeObject(peripheral)
        } else {
            for var i = 0; i < service.characteristics.count; i++ {
                var characteristic:CBCharacteristic = service.characteristics[i] as CBCharacteristic
                if CBUUID.UUIDWithString(kCharacteristicUUID) == characteristic.UUID {
                    
                    var peripheralId:String = lastConnectedPeripheralUUID()
                    if peripheralId == "" {
                        // peripheralId.isEmpty && !isUserCancelConnectingDevices 保证是首次连接设备的情况 ,如果只有 peripheralId.isEmpty的话完全可能是用户取消绑定的情况
                        central.cancelPeripheralConnection(peripheral)
                        if !contains(devices, peripheral) {
                            devices.append(peripheral)
                        }
                        println("first comming")
                    } else if peripheralId == peripheral.identifier.UUIDString {
                        
                        isPeripheralTryToConnect = true
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                        bind(peripheral)
                        disConnectOtherPeripheralAfterBandedAConnectingPeripheral()
                    } else {
                        central.cancelPeripheralConnection(peripheral)
                        if !contains(devices, peripheral) {
                            devices.append(peripheral)
                        }
                    }
                    break
                }
            }
        }
        println("dataSelected--\(devicesArrayOnSelectedStatus.description) ")
        println("dataNoSelected--\(devices.description) ")
        delegate?.centralss(central, unConnectedDevices: devices, connectedDevices: devicesArrayOnSelectedStatus)
    }

    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!){
        println("5--updateValue\(peripheral.identifier.UUIDString)")
        isPeripheralTryToConnect = false
        startSendingDataDelegate?.deviceCentralManagerDidStartsendData() //可以优化
        characteristicDelegate?.didUpdateValueToCharacteristic(characteristic, cError: error)
    }

}
