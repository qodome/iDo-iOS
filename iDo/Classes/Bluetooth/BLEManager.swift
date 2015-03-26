//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

protocol BLEManagerDelegate {
    func onChanged(peripheral: CBPeripheral?, event: BLEManagerEvent)
}

protocol BLEManagerDataSource {
    /** 更新温度值 */
    func onUpdateTemperature(peripheral: CBPeripheral, value: Double)
    
    func onUpdateRSSI(peripheral: CBPeripheral, RSSI: NSNumber)
}

protocol BLEManagerOADSource {
    func onUpdateOADInfo(state: OADState, info: String?, progress: UInt8)
}

enum BLEManagerEvent: Int {
    case PowerOff, Idle, Scan, Discovered, Connecting, Connected, Disconnected, Fail, ServiceDiscovered, Renamed
}

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // MARK: - 🍀 变量
    let PREF_DEFAULT_DEVICE = "default_device"
    
    var central: CBCentralManager!
    var peripherals: [CBPeripheral] = [] // 所有设备
    var delegate: BLEManagerDelegate?
    var dataSource: BLEManagerDataSource?
    var oadHelper: OADHandler?
    
    var kServiceUUIDString = BLE_HEALTH_THERMOMETER
    var kCharacteristicUUIDString = BLE_INTERMEDIATE_TEMPERATURE
    var serviceUUIDs: [CBUUID] = []
    var reconnectCount = 0
    
    var characteristicFirmware: CBCharacteristic? // 方便调用
    
    var peripheralName = "" // 改名用
    
    var rename = false
    
    // SO: http://stackoverflow.com/questions/24024549/dispatch-once-singleton-model-in-swift
    class var sharedManager: BLEManager {
        struct Singleton {
            static let instance = BLEManager()
        }
        return Singleton.instance
    }
    
    // MARK: - 💖 生命周期 (Lifecycle)
    private override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
        //        central = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey : NSNumber(bool: true)])
        serviceUUIDs = [
            CBUUID(string: kServiceUUIDString),
            CBUUID(string: BLE_CURRENT_TIME_SERVICE),
            CBUUID(string: BLE_DEVICE_INFORMATION)
        ]
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func startScan() {
        delegate?.onChanged(nil, event: .Scan)
        central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUIDString)], options: nil)
    }
    
    func connect(peripheral: CBPeripheral) { // 连接
        delegate?.onChanged(peripheral, event: .Connecting)
        central.connectPeripheral(peripheral, options: nil)
    }
    
    /** 绑定设备 */
    func bind(peripheral: CBPeripheral) {
        for peripheral in central.retrieveConnectedPeripheralsWithServices([CBUUID(string: kServiceUUIDString)]) as [CBPeripheral] {
            central.cancelPeripheralConnection(peripheral)
        }
        putString(PREF_DEFAULT_DEVICE, peripheral.identifier.UUIDString)
        connect(peripheral)
    }
    
    /** 解绑设备 */
    func unbind(peripheral: CBPeripheral) {
        Log("解绑 设备 \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        NSUserDefaults.standardUserDefaults().removeObjectForKey(PREF_DEFAULT_DEVICE)
        central.cancelPeripheralConnection(peripheral)
    }
    
    func defaultDevice() -> String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(PREF_DEFAULT_DEVICE)
    }
    
    // MARK: - 💜 CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        Log("蓝牙状态更新 \(central.state.rawValue)")
        var event = BLEManagerEvent.PowerOff
        switch central.state {
        case .PoweredOn:
            event = .Idle
            central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUIDString)], options: nil)
        default:
            peripherals.removeAll(keepCapacity: false)
        }
        delegate?.onChanged(nil, event: event)
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        delegate?.onChanged(peripheral, event: .Discovered)
        if !contains(peripherals, peripheral) { // 加入设备队列
            peripherals.append(peripheral)
        }
        if peripheral.identifier.UUIDString == defaultDevice() {
            if reconnectCount > 0 { // 信号不好
                println("信号不好")
            }
            if peripheral.state == CBPeripheralState.Disconnected {
                connect(peripheral) // 未连接状态下才连接
            }
            // central.stopScan() // 停止搜寻
        }
        let s = peripheral.identifier.UUIDString == defaultDevice() ? "" : "未"
        Log("🆔 发现 \(s)绑定设备 \(peripheral.name) (\(peripheral.identifier.UUIDString))")
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        Log("🛂 连上 设备 \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onChanged(peripheral, event: .Connected)
        oadHelper?.oadHandleEvent(peripheral, event: .Connected)
        peripheral.delegate = self
        peripheral.discoverServices(serviceUUIDs)
    }
    
    // MARK: -      处理异常
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        Log("❌ 连接失败 \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onChanged(peripheral, event: .Fail)
        oadHelper?.oadHandleEvent(peripheral, event: .Fail)
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) { // 这里不是真的断开，会有延时
        Log("🅿️ 断开 设备 \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onChanged(peripheral, event: .Disconnected)
        oadHelper?.oadHandleEvent(peripheral, event: .Disconnected)
        if peripheral.identifier.UUIDString == defaultDevice() { // 断开后无限次自动重连
            if rename {
                delegate?.onChanged(peripheral, event: .Renamed)
                rename = false
            } else {
                reconnectCount++
            }
            connect(peripheral)
        }
    }
    
    // MARK: - 💜 CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error == nil {
            for service in peripheral.services as [CBService] {
                Log("✴️ 发现 服务 \(service.UUID)")
                switch service.UUID.UUIDString {
                case kServiceUUIDString:
                    delegate?.onChanged(peripheral, event: .ServiceDiscovered)
                    peripheral.discoverCharacteristics([CBUUID(string: kCharacteristicUUIDString)], forService: service)
                case BLE_CURRENT_TIME_SERVICE:
                    peripheral.discoverCharacteristics([CBUUID(string: BLE_DATE_TIME)], forService: service)
                case BLE_DEVICE_INFORMATION:
                    peripheral.discoverCharacteristics([CBUUID(string: BLE_MODEL_NUMBER_STRING), CBUUID(string: BLE_FIRMWARE_REVISION_STRING), CBUUID(string: BLE_SERIAL_NUMBER_STRING), CBUUID(string: BLE_MANUFACTURER_NAME_STRING)], forService: service)
                case BLE_QODOME_SERVICE:
                    peripheral.discoverCharacteristics([CBUUID(string: BLE_QODOME_SET_NAME)], forService: service)
                default: break
                }
            }
            oadHelper?.oadHandleEvent(peripheral, event: .ServiceDiscovered)
        } else {
            Log("❌ error in service discovery")
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if error == nil {
            switch service.UUID.UUIDString {
            case kServiceUUIDString:
                for characteristic in service.characteristics as [CBCharacteristic] {
                    if kCharacteristicUUIDString == characteristic.UUID.UUIDString {
                        peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                        break
                    }
                }
            case BLE_CURRENT_TIME_SERVICE:
                for characteristic in service.characteristics as [CBCharacteristic] {
                    Log("✳️ 发现 特性 \(characteristic.UUID)")
                    if BLE_DATE_TIME == characteristic.UUID.UUIDString {
                        let calendar = NSCalendar.autoupdatingCurrentCalendar() // TODO: 用这个日历是否总是对
                        calendar.timeZone = NSTimeZone(name: "UTC")!
                        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond, fromDate: NSDate())
                        let buffer = [UInt8(components.year & 0xFF), UInt8((components.year & 0xFF00) >> 8), UInt8(components.month), UInt8(components.day), UInt8(components.hour), UInt8(components.minute), UInt8(components.second)]
                        peripheral.writeValue(NSData(bytes: buffer, length: buffer.count), forCharacteristic: characteristic, type: .WithResponse)
                        peripheral.readValueForCharacteristic(characteristic)
                    }
                }
            case BLE_DEVICE_INFORMATION:
                if peripheral.deviceInfo == nil { // 不判断的话Discover服务就会反复重置
                    peripheral.deviceInfo = DeviceInfo()
                }
                for characteristic in service.characteristics as [CBCharacteristic] {
                    Log("✳️ 发现 特性 \(characteristic.UUID)")
                    if characteristic.UUID.UUIDString == BLE_FIRMWARE_REVISION_STRING {
                        characteristicFirmware = characteristic
                    }
                    peripheral.readValueForCharacteristic(characteristic)
                }
            case BLE_QODOME_SERVICE:
                if peripheralName != peripheral.name {
                    for characteristic in service.characteristics as [CBCharacteristic] {
                        Log("✳️ 发现 特性 \(characteristic.UUID)")
                        if characteristic.UUID.UUIDString == BLE_QODOME_SET_NAME {
                            peripheral.writeValue(peripheralName.dataUsingEncoding(NSUTF8StringEncoding), forCharacteristic: characteristic, type: .WithResponse)
                        }
                    }
                }
            default:
                Log("✴️ 未知服务 ⁉️ \(service.UUID) ")
            }
            oadHelper?.onCharacteristicDiscovered(peripheral, service: service)
        } else {
            Log("❌ error in char discovery")
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error == nil {
            // Log("❇️ 更新 特性值 \(characteristic.UUID)")
            switch characteristic.UUID.UUIDString {
            case kCharacteristicUUIDString:
                if peripheral.identifier.UUIDString != defaultDevice() { // 强退 TODO: 待优化
                    central.cancelPeripheralConnection(peripheral)
                    return
                }
                reconnectCount = 0 // 取到数据才算一次完整的重连成功
                peripheral.readRSSI()
                dataSource?.onUpdateTemperature(peripheral, value: calculateTemperature(characteristic.value))
            case BLE_DATE_TIME:
                break
            case BLE_MODEL_NUMBER_STRING:
                peripheral.deviceInfo?.modelNumber = getString(characteristic.value)
            case BLE_SERIAL_NUMBER_STRING:
                peripheral.deviceInfo?.serialNumber = getString(characteristic.value)
            case BLE_FIRMWARE_REVISION_STRING:
                peripheral.deviceInfo?.firmwareRevision = getString(characteristic.value)
            case BLE_MANUFACTURER_NAME_STRING:
                peripheral.deviceInfo?.manufacturerName = getString(characteristic.value)
            default: break
            }
            oadHelper?.onUpdateValue(peripheral, characteristic: characteristic)
        } else {
            Log("❌ error in data")
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didReadRSSI RSSI: NSNumber!, error: NSError!) {
        dataSource?.onUpdateRSSI(peripheral, RSSI: RSSI)
    }
    
    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        Log("❇️ 写入 特性 \(characteristic.UUID)")
        if characteristic.UUID.UUIDString == BLE_QODOME_SET_NAME {
            rename = true
            central.cancelPeripheralConnection(peripheral) // 必须断开,改名或重新扫描或直接重连,名字都不会变
        }
    }
}
