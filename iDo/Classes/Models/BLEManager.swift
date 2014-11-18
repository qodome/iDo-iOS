//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

protocol BLEManagerDelegate {
    
    /** 设备已连接 */
    func didConnect(peripheral: CBPeripheral)
    
    /** 设备自动断开连接 */
    func didDisconnect()
    
    /** 更新数据 */
    func didUpdateValue(characteristic: CBCharacteristic?)
}

protocol DeviceChangeDelegate {
    func onDataChange(unconnected: [CBPeripheral], connected: CBPeripheral?)
}

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: - 🍀 变量
    let kServiceUUID = "1809" // Health Thermometer
    let kCharacteristicUUID = "2A1C" // Temperature Measurement
    let PREF_DEFAULT_DEVICE = "selectedPeripheralId"
    
    var central: CBCentralManager!
    var isPeripheralTryToConnect = false
    var connected: CBPeripheral? // 已连接设备
    var peripherals: [CBPeripheral] = [] // 未连接设备
    var delegate: BLEManagerDelegate! // 温度数据发送 代理
    var changeDelegate: DeviceChangeDelegate? //设备data变化 代理
    
    // MARK: - 💖 生命周期 (Lifecycle)
    class func sharedManager() -> BLEManager {
        struct Singleton{
            static var predicate: dispatch_once_t = 0
            static var instance: BLEManager? = nil
        }
        dispatch_once(&Singleton.predicate, {
            Singleton.instance = BLEManager()
            println("instance")
        })
        return Singleton.instance!
    }
    
    override init() {
        super.init()
        //        central = CBCentralManager(delegate: self, queue: nil)
        central = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: NSNumber(bool: true)])
    }
    
    // MARK: 💛 自定义方法
    func startScan() {
        central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUID)], options: nil)
    }
    
    func connect(index: Int) {
        if connected != nil {
            unbind(connected!)
        }
        let peripheral = peripherals[index]
        NSUserDefaults.standardUserDefaults().setObject(peripheral.identifier.UUIDString, forKey: PREF_DEFAULT_DEVICE)
        isPeripheralTryToConnect = true
        central.connectPeripheral(peripheral, options: nil) // 连接
        peripherals.removeAtIndex(index)
        changeDelegate?.onDataChange(peripherals, connected: connected)
    }
    
    /** 解绑设备 */
    func unbind(peripheral: CBPeripheral) {
        NSLog("解绑设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
        NSUserDefaults.standardUserDefaults().setObject("", forKey: PREF_DEFAULT_DEVICE)
        connected = nil
        if !contains(peripherals, peripheral) {
            peripherals.append(peripheral)
        }
        isPeripheralTryToConnect = false
        delegate.didUpdateValue(nil)
        changeDelegate?.onDataChange(peripherals, connected: connected) // 刷新UI
        central.cancelPeripheralConnection(peripheral)
    }
    
    func defaultDevice() -> String {
        if NSUserDefaults.standardUserDefaults().objectForKey(PREF_DEFAULT_DEVICE) == nil {
            NSUserDefaults.standardUserDefaults().setObject("", forKey: PREF_DEFAULT_DEVICE)
        }
        return NSUserDefaults.standardUserDefaults().objectForKey(PREF_DEFAULT_DEVICE) as String
    }
    
    // MARK: - 💙 CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        NSLog("💙 蓝牙状态更新: %i", central.state.rawValue)
        switch central.state {
        case CBCentralManagerState.PoweredOn:
            central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUID)], options: nil)
        default:
            connected = nil
            peripherals.removeAll(keepCapacity: true)
            delegate.didUpdateValue(nil)
            changeDelegate?.onDataChange(peripherals, connected: connected)
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if peripheral.identifier.UUIDString == defaultDevice() {
            NSLog("💙 发现已绑定设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
            isPeripheralTryToConnect = true
            connected = peripheral
            central.connectPeripheral(peripheral, options:nil)
        } else {
            NSLog("💙 发现未绑定设备: \(peripheral.name) (%@)", peripheral.identifier.UUIDString)
            if !contains(peripherals, peripheral) {
                peripherals.append(peripheral)
            }
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("💙 连上设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
        central.stopScan() // 停止搜寻
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: kServiceUUID)])
        //设备已连接
        delegate.didConnect(peripheral)
        isPeripheralTryToConnect = false
        changeDelegate?.onDataChange(peripherals, connected: peripheral)
    }
    
    // MARK: -      处理异常
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("💙 连接失败: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("💙 断开设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
        //NSLog("💙 error: %@", error.localizedDescription)
        var peripheralId: String = defaultDevice()
        NSLog("disconnectedPeripheralId:%@", peripheralId)
        if peripheralId == peripheral.identifier.UUIDString {
            NSLog("autoDisConnected")
            connected = nil
            if !contains(peripherals, peripheral) {
                peripherals.append(peripheral)
            }
            changeDelegate?.onDataChange(peripherals, connected: connected)
            delegate.didDisconnect()
        }
    }
    
    // MARK: - 💙 CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error != nil {
            // devicesArray.removeObject(peripheral)
        } else {
            for service in peripheral.services {
                if CBUUID(string: kServiceUUID) == service.UUID {
                    peripheral.discoverCharacteristics([CBUUID(string: kCharacteristicUUID)], forService: service as CBService)
                    break
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if error != nil {
            //  devicesArray.removeObject(peripheral)
        } else {
            for characteristic in service.characteristics {
                if CBUUID(string: kCharacteristicUUID) == characteristic.UUID {
                    var peripheralId: String = defaultDevice()
                    NSLog("disCharactristicPID - %@", peripheralId)
                    //                    if peripheralId == "" {
                    //                        // peripheralId.isEmpty && !isUserCancelConnectingDevices 保证是首次连接设备的情况 ,如果只有 peripheralId.isEmpty的话完全可能是用户取消绑定的情况
                    //                        central.cancelPeripheralConnection(peripheral)
                    //                        if !contains(devices, peripheral) {
                    //                            devices.append(peripheral)
                    //                        }
                    //                        println("first comming")
                    //                    } else
                    if peripheralId == peripheral.identifier.UUIDString {
                        //isPeripheralTryToConnect = true
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
                        //bind(peripheral)
                    }
                    //                    else {
                    //                        central.cancelPeripheralConnection(peripheral)
                    //                        if !contains(devices, peripheral) {
                    //                            devices.append(peripheral)
                    //                        }
                }
                break
                //                }
            }
        }
        changeDelegate?.onDataChange(peripherals, connected: connected)
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error != nil {
        } else {
            delegate.didUpdateValue(characteristic)
        }
    }
}
