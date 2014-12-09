//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

protocol BLEManagerDelegate {
    func onStateChanged(state: BLEManagerState, peripheral: CBPeripheral?)
}

protocol BLEManagerDataSource {
    /** 更新温度值 */
    func onUpdateTemperature(value: Double)
}

enum BLEManagerState: Int {
    case PowerOff
    case Idle
    case Scan
    case Discovered
    case Connecting
    case Connected
    case Disconnected
    case Fail
    case ServiceDiscovered
}

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: - 🍀 变量
    let PREF_DEFAULT_DEVICE = "default_device"
    
    var central: CBCentralManager!
    var peripherals: [CBPeripheral] = [] // 所有设备
    var delegate: BLEManagerDelegate?
    var dataSource: BLEManagerDataSource?
    
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
        central = CBCentralManager(delegate: self, queue: nil)
//        central = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey : NSNumber(bool: true)])
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func startScan() {
        println("aaa=========================")
        central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUID)], options: nil)
    }
    
    func connect(peripheral: CBPeripheral) { // 连接
        delegate?.onStateChanged(.Connecting, peripheral: peripheral)
        central.connectPeripheral(peripheral, options: nil)
    }
    
    /** 绑定设备 */
    func bind(peripheral: CBPeripheral) {
        for peripheral in central.retrieveConnectedPeripheralsWithServices([CBUUID(string: kServiceUUID)]) as [CBPeripheral] {
            central.cancelPeripheralConnection(peripheral)
        }
        NSUserDefaults.standardUserDefaults().setObject(peripheral.identifier.UUIDString, forKey: PREF_DEFAULT_DEVICE)
        connect(peripheral)
    }
    
    /** 解绑设备 */
    func unbind(peripheral: CBPeripheral) {
        Log("解绑设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        NSUserDefaults.standardUserDefaults().removeObjectForKey(PREF_DEFAULT_DEVICE)
        central.cancelPeripheralConnection(peripheral)
    }
    
    func defaultDevice() -> String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(PREF_DEFAULT_DEVICE)
    }
    
    // MARK: - 💙 CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        Log("蓝牙状态更新: \(central.state.rawValue)")
        var state = BLEManagerState.PowerOff
        switch central.state {
        case .PoweredOn:
            state = .Idle
            central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUID)], options: nil)
        default:
            peripherals.removeAll(keepCapacity: false)
        }
        delegate?.onStateChanged(state, peripheral: nil)
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        delegate?.onStateChanged(.Discovered, peripheral: peripheral)
        if !contains(peripherals, peripheral) {
            peripherals.append(peripheral)
        }
        if peripheral.identifier.UUIDString == defaultDevice() {
            Log("发现已绑定设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
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
                //                            println(@"%d", *ptr & 0xFFFFFF)
                //                        }
                //                    }
                //                }
            }
        } else {
            Log("发现未绑定设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        Log("连上设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onStateChanged(.Connected, peripheral: peripheral)
        central.stopScan() // 停止搜寻
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: kServiceUUID), CBUUID(string: BLE_UUID_DATE)])
    }
    
    // MARK: -      处理异常
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        Log("连接失败: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onStateChanged(.Fail, peripheral: peripheral)
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) { // 这里不是真的断开，会有延时
        Log("断开设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onStateChanged(.Disconnected, peripheral: peripheral)
        if peripheral.identifier.UUIDString == defaultDevice() { // 无限次自动重连
            if reconnectCount > 0 {
                startScan()
            } else {
                reconnectCount++
                println("重连")
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
                    println("aaaaabbbbb")
                    delegate?.onStateChanged(.ServiceDiscovered, peripheral: peripheral)
                    println("aaaaabbbbbcccccc")
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
                if peripheral.identifier.UUIDString != defaultDevice() { // 强退 TODO: 待优化
                    central.cancelPeripheralConnection(peripheral)
                    return
                }
                dataSource?.onUpdateTemperature(calculateTemperature(characteristic.value))
            case CBUUID(string: BLE_UUID_DATE_TIME_CHAR):
                println("🔵 usdfsadfasdfasdfsdf")
                println("\(characteristic)")
            default:
                println("🔵 unknown characteristic")
            }
        } else {
            central.cancelPeripheralConnection(peripheral)
        }
    }
}
