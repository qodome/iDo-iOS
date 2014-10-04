//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

//优化

protocol DeviceCentralManagerDidStartsendDataDelegate {
    func  deviceCentralManagerDidStartsendData()
}

protocol DeviceCentralManagerdidUpdateValueToCharacterisrticDelegate {
   func didUpdateValueToCharacteristic(characteristic:CBCharacteristic? ,cError error:NSError?)
}

protocol DeviceCentralManagerdidChangedCurrentConnectedDeviceDelegate {
    func central(center:CBCentralManager, unConnectedDevices unConnectedDeviceArr:NSArray, connectedDevices connectedDeviceArr:NSArray)
}

class DeviceCentralManager: NSObject {
    
    let kServiceUUID:String = "1809"// Health Thermometer
    let kCharacteristicUUID = "2A1C" // Temperature Measurement

    var isShowAllCanConnectedDevices: Bool = false // 只有在用户点击刷新设备button后或者第一次进入appp 才为true
    var isUserCancelConnectingDevices: Bool = false // 用户手动取消连接是为true
    var isPeripheralTryToConnect: Bool = false
   // var isScanning: Bool = false //// 只有在用户点击刷新设备button后或者第一次进入appp 才为true
    
    var devicesArrayOnSelectedStatus: NSMutableArray! //放置已经连接的peripheral
    var devices: NSMutableArray! //放置可连接的(但未连接的)peripherals
    var devicesArray: NSMutableArray! //保持指向peripherals的引用,不然会peripheras会丢失
    
    var startSendingDataDelegate: DeviceCentralManagerDidStartsendDataDelegate? // 
    var characteristicDelegate: DeviceCentralManagerdidUpdateValueToCharacterisrticDelegate? //温度数据发送 代理
    var delegate: DeviceCentralManagerdidChangedCurrentConnectedDeviceDelegate? //设备data变化 代理
    var devicesCentralManager: CBCentralManager!
    var currentPeripheral: CBPeripheral!
    
    // MARK: - 生命周期 (Lifecyle)
    class func instanceForCenterManager()->DeviceCentralManager{
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
    
    override init(){
        super.init()
         println("init")
        devicesDataInit()
    }
    
    // MARK: - custom method
    
    func devicesDataInit(){
        println("devicesInit")
        devicesCentralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey:NSNumber.numberWithBool(true)])
        devicesArray = NSMutableArray()
        devicesArrayOnSelectedStatus = NSMutableArray()
        devices = NSMutableArray()
    }

    func userConnectPeripheral(peripheral:CBPeripheral!){
        let lastPeripheral :CBPeripheral? = devicesArrayOnSelectedStatus.lastObject as? CBPeripheral
        if lastPeripheral != nil {
            userCancelConnectPeripheral(lastPeripheral)
        }
        bindPeripheral(peripheral)
        devicesCentralManager.connectPeripheral(peripheral, options: nil)
        devices.removeObject(peripheral)
        
        isPeripheralTryToConnect = true
        ////
        delegate?.central(devicesCentralManager, unConnectedDevices: devices, connectedDevices: devicesArrayOnSelectedStatus)
    }
    
    func userCancelConnectPeripheral(peripheral:CBPeripheral!){
        unBindPeripheral(peripheral)
        isPeripheralTryToConnect = false
        ////
        characteristicDelegate?.didUpdateValueToCharacteristic(nil, cError: nil)
        delegate?.central(devicesCentralManager, unConnectedDevices: devices, connectedDevices: devicesArrayOnSelectedStatus)
    }

    func startScanPeripherals(){
       // isScanning = true
        devicesCentralManager.scanForPeripheralsWithServices([CBUUID.UUIDWithString(kServiceUUID)], options: nil)
        
        
    }
    
    func stopScanPeripherals() {
        //isScanning = false
        devicesCentralManager.stopScan();
    }
    
    func bindPeripheral(peripheral:CBPeripheral!){
        println("bindPeripheral")
        setConnectingPeripheralUUID(peripheral.identifier.UUIDString)
        isUserCancelConnectingDevices = false
        if(!isShowAllCanConnectedDevices){
            stopScanPeripherals()
        }
        isPeripheralTryToConnect =  true
        if !devicesArrayOnSelectedStatus.containsObject(peripheral)
        {
            devicesArrayOnSelectedStatus.addObject(peripheral)
        }
    }
    
    func unBindPeripheral(peripheral:CBPeripheral!){
        setConnectingPeripheralUUID("")
        isUserCancelConnectingDevices = true
        devicesCentralManager.cancelPeripheralConnection(peripheral)
        devicesArrayOnSelectedStatus.removeLastObject()
        if !devices.containsObject(peripheral) {
            devices .addObject(peripheral)
        }
    }
    
    func disConnectOtherPeripheralAfterBandedAConnectingPeripheral(){
        if devices.count != 0{
            for var i=0;i<devicesArray.count;i++ {
                var mPeripheral:CBPeripheral = devicesArray[i] as CBPeripheral
                //////
                //a != b
                if self.lastConnectedPeripheralUUID() != mPeripheral.identifier.UUIDString{
                    devicesCentralManager.cancelPeripheralConnection(mPeripheral)
                    devicesArray.removeObject(mPeripheral)
                }
            }
        }
        
    }
    
    func lastConnectedPeripheralUUID()->String {
        if NSUserDefaults.standardUserDefaults().objectForKey("selectedPeripheralId") == nil {
            setConnectingPeripheralUUID("")
        }
        return NSUserDefaults.standardUserDefaults().objectForKey("selectedPeripheralId") as String
    }
    
    func setConnectingPeripheralUUID(peripheralUUID:String?) {
        return NSUserDefaults.standardUserDefaults().setObject(peripheralUUID, forKey:"selectedPeripheralId")
    }
    
}

// MARK: - DeviceCentralManager delegate

extension DeviceCentralManager: CBCentralManagerDelegate{
    
    func centralManagerDidUpdateState(central: CBCentralManager!)
    {
        println("centeral manager did update state--\(central.state)")
        central.scanForPeripheralsWithServices([CBUUID.UUIDWithString(kServiceUUID)], options: [CBCentralManagerOptionShowPowerAlertKey:NSNumber.numberWithBool(true)])
        if CBCentralManagerState.PoweredOff == central.state {
            devicesArrayOnSelectedStatus.removeAllObjects()
            devices.removeAllObjects()
             characteristicDelegate?.didUpdateValueToCharacteristic(nil, cError: nil)
            delegate?.central(devicesCentralManager, unConnectedDevices: devices, connectedDevices: devicesArrayOnSelectedStatus)
        }
    }

    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: NSDictionary!, RSSI: NSNumber!)
    {
        println("1-centeral Manager did disCoverPeripheral\(peripheral.identifier)")
        println()
        if !devicesArray.containsObject(peripheral) {
            
            devicesArray.addObject(peripheral)
        }
        
        var peripheralId:String = lastConnectedPeripheralUUID()
       // println("perID-\(peripheralId) currentState:\(peripheral)")
        if isShowAllCanConnectedDevices {
            println("刷新")
            central.connectPeripheral(peripheral, options:nil)
        } else if peripheralId == "" {
            //未绑定 连接所有
            println("未绑定")
            central.connectPeripheral(peripheral, options:nil)
        } else if peripheralId == peripheral.identifier.UUIDString {
            //有绑定 只试图连接 绑定的设备
            println("绑定")
            bindPeripheral(peripheral)
           central.connectPeripheral(peripheral, options:nil)
        }
        
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("2-did connect peripheral")
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID.UUIDWithString(kServiceUUID)])
    }
    
    ////////////////////////////处理异常
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("did dis connect peripheral")
        devicesArray.removeObject(peripheral)
        var peripheralId:String = lastConnectedPeripheralUUID()
        println("dis connect pID \(peripheralId)")
//        if peripheralId == peripheral.identifier.UUIDString {
//            central.connectPeripheral(peripheral, options: nil)
//        }
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
         println("did  fail")
        devicesArray.removeObject(peripheral)
        var peripheralId:String = lastConnectedPeripheralUUID()
//        if peripheralId == peripheral.identifier.UUIDString {
//            central.connectPeripheral(peripheral, options: nil)
//        }
    }
    ////////////
}

// MARK: - CBPeripheralDelegate delegate

extension DeviceCentralManager: CBPeripheralDelegate {
   
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!){
        println("3-peripheral\(peripheral.identifier) did discover services)")
        if error != nil {
           // devicesArray.removeObject(peripheral)
        } else {
            for (var i = 0; i<peripheral.services.count; i++){
                var service:CBService = peripheral.services[i] as CBService
                if CBUUID.UUIDWithString(kServiceUUID) == service.UUID {
                    peripheral.discoverCharacteristics([CBUUID.UUIDWithString(kCharacteristicUUID)], forService: service)
                    break
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!){
        println("4-check out characteristics")
        if error != nil {
          //  devicesArray.removeObject(peripheral)
        } else {
            for(var i=0;i<service.characteristics.count;i++){
                var characteristic:CBCharacteristic = service.characteristics[i] as CBCharacteristic
                if CBUUID.UUIDWithString(kCharacteristicUUID) == characteristic.UUID {
                    
                    var peripheralId:String = lastConnectedPeripheralUUID()
                    if peripheralId == "" {
                        // peripheralId.isEmpty && !isUserCancelConnectingDevices 保证是首次连接设备的情况 ,如果只有 peripheralId.isEmpty的话完全可能是用户取消绑定的情况
                        devicesCentralManager.cancelPeripheralConnection(peripheral)
                        if !devices.containsObject(peripheral){
                            devices .addObject(peripheral)
                        }
                        println("first comming")
                    } else if peripheralId == peripheral.identifier.UUIDString {
                        
                        isPeripheralTryToConnect = true
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                        bindPeripheral(peripheral)
                        disConnectOtherPeripheralAfterBandedAConnectingPeripheral()
                    } else {
                        devicesCentralManager.cancelPeripheralConnection(peripheral)
                        if !devices.containsObject(peripheral){
                            devices.addObject(peripheral)
                        }
                    }
                    break
                }
            }
        }
        println("dataSelected--\(devicesArrayOnSelectedStatus.description) ")
        println("dataNoSelected--\(devices.description) ")
        delegate?.central(devicesCentralManager, unConnectedDevices: devices, connectedDevices: devicesArrayOnSelectedStatus)
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!){
        println("5--updateValue\(peripheral.identifier.UUIDString)")
        isPeripheralTryToConnect = false
        startSendingDataDelegate?.deviceCentralManagerDidStartsendData() //可以优化
        characteristicDelegate?.didUpdateValueToCharacteristic(characteristic, cError: error)
    }

}
