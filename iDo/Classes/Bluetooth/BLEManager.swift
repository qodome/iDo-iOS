//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

protocol BLEManagerDelegate {
    func onStateChanged(state: BLEManagerState, peripheral: CBPeripheral?)
}

protocol BLEManagerDataSource {
    /** 更新温度值 */
    func onUpdateTemperature(value: Double, peripheral: CBPeripheral?)
}

protocol BLEManagerOADSource {
    func onUpdateOADInfo(status: OADStatus, info: String?, progress: UInt8)
}

enum BLEManagerState: Int {
    case PowerOff, Idle, Scan, Discovered, Connecting, Connected, Disconnected, Fail,ServiceDiscovered, CharacteristicDiscovered, DataReceived
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
            CBUUID(string: BLE_DEVICE_INFORMATION),
            CBUUID(string: IDO1_OAD_SERVICE)
        ]
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func startScan() {
        delegate?.onStateChanged(.Scan, peripheral: nil)
        central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUIDString)], options: nil)
    }
    
    func connect(peripheral: CBPeripheral) { // 连接
        delegate?.onStateChanged(.Connecting, peripheral: peripheral)
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
        Log("解绑 设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
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
            central.scanForPeripheralsWithServices([CBUUID(string: kServiceUUIDString)], options: nil)
        default:
            peripherals.removeAll(keepCapacity: false)
        }
        delegate?.onStateChanged(state, peripheral: nil)
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        delegate?.onStateChanged(.Discovered, peripheral: peripheral)
        if !contains(peripherals, peripheral) { // 加入设备队列
            peripherals.append(peripheral)
        }
        if peripheral.identifier.UUIDString == defaultDevice() {
            if reconnectCount > 0 { // 信号不好
                println("信号不好")
            }
            connect(peripheral) // 连接
            central.stopScan() // 停止搜寻
        }
        let s = peripheral.identifier.UUIDString == defaultDevice() ? "" : "未"
        Log("发现 \(s)绑定设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        Log("💟 连上 设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onStateChanged(.Connected, peripheral: peripheral)
        oadHelper?.oadHandleEvent(peripheral, event: .Connected, eventData: nil)
//        central.stopScan() // 停止搜寻
        peripheral.delegate = self
        peripheral.discoverServices(serviceUUIDs)
    }
    
    // MARK: -      处理异常
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        Log("连接失败: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onStateChanged(.Fail, peripheral: peripheral)
        oadHelper?.oadHandleEvent(peripheral, event: .Fail, eventData: nil)
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) { // 这里不是真的断开，会有延时
        Log("断开 设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onStateChanged(.Disconnected, peripheral: peripheral)
        oadHelper?.oadHandleEvent(peripheral, event: .Disconnected, eventData: nil)
        if peripheral.identifier.UUIDString == defaultDevice() { // 无限次自动重连
            reconnectCount++
            connect(peripheral)
        }
    }
    
    // MARK: - 💙 CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error == nil {
            for service in peripheral.services as [CBService] {
                Log("✴️ 发现 服务 \(service.UUID)")
                switch service.UUID.UUIDString {
                case kServiceUUIDString:
                    delegate?.onStateChanged(.ServiceDiscovered, peripheral: peripheral)
                    peripheral.discoverCharacteristics([CBUUID(string: kCharacteristicUUIDString)], forService: service)
                case BLE_CURRENT_TIME_SERVICE:
                    peripheral.discoverCharacteristics([CBUUID(string: BLE_DATE_TIME)], forService: service)
                case BLE_DEVICE_INFORMATION:
                    peripheral.discoverCharacteristics([CBUUID(string: BLE_MODEL_NUMBER_STRING), CBUUID(string: BLE_SERIAL_NUMBER_STRING), CBUUID(string: BLE_FIRMWARE_REVISION_STRING), CBUUID(string: BLE_SOFTWARE_REVISION_STRING), CBUUID(string: BLE_MANUFACTURER_NAME_STRING)], forService: service)
                case IDO1_OAD_SERVICE:
                    peripheral.discoverCharacteristics([CBUUID(string: IDO1_OAD_IDENTIFY), CBUUID(string: IDO1_OAD_BLOCK)], forService: service)
                default: break
                }
            }
        } else {
            println("error in service discovery")
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
                        let bytes: [UInt8] = [UInt8(components.year & 0xFF), UInt8((components.year & 0xFF00) >> 8), UInt8(components.month), UInt8(components.day), UInt8(components.hour), UInt8(components.minute), UInt8(components.second)]
//                        println(bytes)
                        peripheral.writeValue(NSData(bytes: bytes, length: bytes.count), forCharacteristic: characteristic, type: .WithResponse)
                        peripheral.readValueForCharacteristic(characteristic)
                    }
                }
            case BLE_DEVICE_INFORMATION:
                for characteristic in service.characteristics as [CBCharacteristic] {
                    Log("✳️ 发现 特性 \(characteristic.UUID)")
                    peripheral.readValueForCharacteristic(characteristic)
                }
            default:
                Log("✴️ 未知服务 \(service.UUID) ⁉️ ")
            }
        } else {
            println("error in char discovery")
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
                dataSource?.onUpdateTemperature(calculateTemperature(characteristic.value), peripheral: peripheral)
            case BLE_DATE_TIME:
                break
            case BLE_MODEL_NUMBER_STRING:
                let info = peripheral.deviceInfo == nil ? DeviceInfo() : peripheral.deviceInfo
                info?.modelNumber = getString(characteristic.value)
                peripheral.deviceInfo = info
            case BLE_SERIAL_NUMBER_STRING:
                let info = peripheral.deviceInfo == nil ? DeviceInfo() : peripheral.deviceInfo
                info?.serialNumber = getString(characteristic.value)
                peripheral.deviceInfo = info
            case BLE_FIRMWARE_REVISION_STRING:
                let info = peripheral.deviceInfo == nil ? DeviceInfo() : peripheral.deviceInfo
                info?.firmwareRevision = getString(characteristic.value)
                peripheral.deviceInfo = info
            case BLE_SOFTWARE_REVISION_STRING:
                let info = peripheral.deviceInfo == nil ? DeviceInfo() : peripheral.deviceInfo
                info?.softwareRevision = getString(characteristic.value)
                peripheral.deviceInfo = info
            case BLE_MANUFACTURER_NAME_STRING:
                let info = peripheral.deviceInfo == nil ? DeviceInfo() : peripheral.deviceInfo
                info?.manufacturerName = getString(characteristic.value)
                peripheral.deviceInfo = info
            default: break
            }
            oadHelper?.oadHandleEvent(peripheral, event: .DataReceived, eventData: characteristic)
        } else {
            println("error in data")
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didReadRSSI RSSI: NSNumber!, error: NSError!) {
        Log("RSSI \(RSSI)")
    }
}
