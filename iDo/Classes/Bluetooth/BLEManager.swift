//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

protocol BLEManagerDelegate {
    
    /** 设备已连接 */
    func didConnect(peripheral: CBPeripheral)
    
    /** 设备断开连接 */
    func didDisconnect()
    
    /** 更新数据 */
    func didUpdateValue(characteristic: CBCharacteristic?)
}

protocol DeviceChangeDelegate {
    func onDataChange(unconnected: [CBPeripheral], connected: CBPeripheral?)
}

enum BLEManagerState: Int {
    case Idle
    case Scan
    case Connecting
    case Connected
    case Disconnected
}

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: - 🍀 变量
    let PREF_DEFAULT_DEVICE = "selectedPeripheralId"
    
    var central: CBCentralManager!
    var connected: CBPeripheral? // 已连接设备
    var peripherals: [CBPeripheral] = [] // 未连接设备
    var state = BLEManagerState.Idle
    var delegate: BLEManagerDelegate! // 温度数据发送 代理
    var changeDelegate: DeviceChangeDelegate? //设备data变化 代理
    
    var reconnectCount = 0
    
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
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func startScan() {
        println("aaa=========================")
        central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUID)], options: nil)
    }
    
    func connect(peripheral: CBPeripheral) { // 连接
        state = .Connecting
        central.connectPeripheral(peripheral, options: nil)
    }
    
    /** 绑定设备 */
    func bind(index: Int) {
        if connected != nil {
            central.cancelPeripheralConnection(connected) // TODO: 解绑的设备需要放到下面去
        }
        let peripheral = peripherals[index]
        NSUserDefaults.standardUserDefaults().setValue(peripheral.identifier.UUIDString, forKey: PREF_DEFAULT_DEVICE)
        peripherals.removeAtIndex(index)
        connected = peripheral
        changeDelegate?.onDataChange(peripherals, connected: connected)
        connect(peripheral)
    }
    
    /** 解绑设备 */
    func unbind(peripheral: CBPeripheral) {
        NSLog("解绑设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
        NSUserDefaults.standardUserDefaults().setValue("", forKey: PREF_DEFAULT_DEVICE)
        central.cancelPeripheralConnection(peripheral)
    }
    
    func defaultDevice() -> String {
        if NSUserDefaults.standardUserDefaults().objectForKey(PREF_DEFAULT_DEVICE) == nil {
            NSUserDefaults.standardUserDefaults().setValue("", forKey: PREF_DEFAULT_DEVICE)
        }
        return NSUserDefaults.standardUserDefaults().valueForKey(PREF_DEFAULT_DEVICE) as String
    }
    
    // MARK: - 💙 CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        NSLog("🔵 蓝牙状态更新: %i", central.state.rawValue)
        switch central.state {
        case CBCentralManagerState.PoweredOn:
            central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUID)], options: nil)
        default:
            connected = nil
            peripherals.removeAll(keepCapacity: true)
            changeDelegate?.onDataChange(peripherals, connected: connected)
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if peripheral.identifier.UUIDString == defaultDevice() {
            NSLog("🔵 发现已绑定设备: \(peripheral.name) (%@)", peripheral.identifier.UUIDString)
            connected = peripheral
            connect(peripheral)
            println("重连次数 \(reconnectCount)")
            if reconnectCount > 0 {
                reconnectCount = 0
                //                println(advertisementData)
                //                var d: NSDictionary = advertisementData as NSDictionary
                //                var srvdata: NSDictionary? = d.objectForKey("kCBAdvData?ServiceData") as? NSDictionary
                //                if srvdata != nil {
                //                    for key in srvdata.allKeys {
                //                        var b: NSData = srvdata.objectForKey(key)
                //                        if b != nil {
                //                            var ptr = (int *)[b bytes]
                //                            NSLog(@"%d", *ptr & 0xFFFFFF)
                //                        }
                //                    }
                //                }
            }
        } else {
            NSLog("🔵 发现未绑定设备: \(peripheral.name) (%@)", peripheral.identifier.UUIDString)
            if !contains(peripherals, peripheral) {
                peripherals.append(peripheral)
                changeDelegate?.onDataChange(peripherals, connected: connected)
            }
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        NSLog("🔵 连上设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
        central.stopScan() // 停止搜寻
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: kServiceUUID), CBUUID(string: BLE_UUID_DATE)])
        delegate.didConnect(peripheral)
        changeDelegate?.onDataChange(peripherals, connected: peripheral)
        state = .Connected
    }
    
    // MARK: -      处理异常
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("🔵 连接失败: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        NSLog("🔵 断开设备: %@ (%@)", peripheral.name, peripheral.identifier.UUIDString)
        state = .Disconnected
        connected = nil
        if !contains(peripherals, peripheral) {
            peripherals.append(peripheral)
        }
        changeDelegate?.onDataChange(peripherals, connected: connected) // 刷新UI
        delegate.didDisconnect() // TODO: 状态有错
        if defaultDevice() != "" { // 无限次自动重连
            if reconnectCount > 0 {
                startScan()
            } else {
                reconnectCount++
                connect(peripheral)
            }
        }
    }
    
    // MARK: - 💙 CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error == nil {
            for service in peripheral.services as [CBService] {
                println("🔵 发现服务 \(service.UUID)")
                switch service.UUID {
                case CBUUID(string: kServiceUUID):
                    peripheral.discoverCharacteristics([CBUUID(string: kCharacteristicUUID)], forService: service)
                case CBUUID(string: BLE_UUID_DATE):
                    peripheral.discoverCharacteristics([CBUUID(string: BLE_UUID_DATE_TIME_CHAR)], forService: service)
                default:
                    println("🔵 unknown service")
                }
            }
        } else {
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if error == nil {
            switch service.UUID {
            case CBUUID(string: kServiceUUID):
                for characteristic in service.characteristics as [CBCharacteristic] {
                    if CBUUID(string: kCharacteristicUUID) == characteristic.UUID {
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                        break
                    }
                }
            case CBUUID(string: BLE_UUID_DATE):
                for characteristic in service.characteristics as [CBCharacteristic] {
                    println("🔵 发现特性 \(characteristic.UUID)")
                    if CBUUID(string: BLE_UUID_DATE_TIME_CHAR) == characteristic.UUID {
                        let calendar = NSCalendar.autoupdatingCurrentCalendar() // TODO: 用这个日历是否总是对
                        calendar.timeZone = NSTimeZone(name: "UTC")!
                        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond, fromDate: NSDate())
                        let bytes: [UInt8] = [UInt8(components.year & 0xFF), UInt8((components.year & 0xFF00) >> 8), UInt8(components.month), UInt8(components.day), UInt8(components.hour), UInt8(components.minute), UInt8(components.second)]
                        println(bytes)
                        println(bytes.count)
                        println("=======fsdfasfsdfa=====")
                        peripheral.writeValue(NSData(bytes: bytes, length: bytes.count), forCharacteristic: characteristic, type: .WithResponse)
                        peripheral.readValueForCharacteristic(characteristic)
                    }
                }
            default:
                println("🔵 unknown service")
            }
        } else {
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error == nil {
            switch characteristic.UUID {
            case CBUUID(string: kCharacteristicUUID):
                delegate.didUpdateValue(characteristic)
            case CBUUID(string: BLE_UUID_DATE_TIME_CHAR):
                println("🔵 usdfsadfasdfasdfsdf")
                NSLog("%@", characteristic)
            default:
                println("🔵 unknown characteristic")
            }
        } else {
            central.cancelPeripheralConnection(peripheral)
        }
    }
}
