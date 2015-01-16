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
    case PowerOff
    case Idle
    case Scan
    case Discovered
    case Connecting
    case Connected
    case Disconnected
    case Fail
    case ServiceDiscovered
    case CharacteristicDiscovered
    case DataReceived
}

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, OADHandlerDelegate {
    // MARK: - 🍀 变量
    let PREF_DEFAULT_DEVICE = "default_device"
    
    var central: CBCentralManager!
    var peripherals: [CBPeripheral] = [] // 所有设备
    var delegate: BLEManagerDelegate?
    var dataSource: BLEManagerDataSource?
    var oadHelper: OADHandler?
    var oadSource: BLEManagerOADSource?
    
    var kServiceUUID = BLE_HEALTH_THERMOMETER
    var kCharacteristicUUID = BLE_INTERMEDIATE_TEMPERATURE
    
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
        delegate?.onStateChanged(.Scan, peripheral: nil)
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
        if !contains(peripherals, peripheral) { // 加入设备队列
            peripherals.append(peripheral)
        }
        if peripheral.identifier.UUIDString == defaultDevice() {
            if reconnectCount > 0 { // 信号不好
                println("信号不好 \(serviceData)")
            }
            connect(peripheral) // 连接
            central.stopScan() // 停止搜寻
        }
        let s = peripheral.identifier.UUIDString == defaultDevice() ? "" : "未"
        Log("发现\(s)绑定设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        Log("连上设备: \(peripheral.name) (\(peripheral.identifier.UUIDString))")
        delegate?.onStateChanged(.Connected, peripheral: peripheral)
//        central.stopScan() // 停止搜寻
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: kServiceUUID), CBUUID(string: BLE_CURRENT_TIME_SERVICE)])
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
            reconnectCount++
            connect(peripheral)
        }
        oadHelper?.oadHandleEvent(peripheral, event: BLEManagerState.Disconnected, eventData: nil, error: nil)
    }
    
    // MARK: - 💙 CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error == nil {
            for service in peripheral.services as [CBService] {
                Log("🔵 发现服务 \(service.UUID)")
                switch service.UUID {
                case CBUUID(string: kServiceUUID):
                    delegate?.onStateChanged(.ServiceDiscovered, peripheral: peripheral)
                    peripheral.discoverCharacteristics([CBUUID(string: kCharacteristicUUID)], forService: service)
                case CBUUID(string: BLE_CURRENT_TIME_SERVICE):
                    peripheral.discoverCharacteristics([CBUUID(string: BLE_DATE_TIME)], forService: service)
                default:
                    Log("🔵 未知服务 \(service.UUID)")
                }
            }
        } else {
            central.cancelPeripheralConnection(peripheral)
        }
        oadHelper?.oadHandleEvent(peripheral, event: BLEManagerState.ServiceDiscovered, eventData: nil, error: error)
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
            case CBUUID(string: BLE_CURRENT_TIME_SERVICE):
                for characteristic in service.characteristics as [CBCharacteristic] {
                    println("🔵 发现特性 \(characteristic.UUID)")
                    if CBUUID(string: BLE_DATE_TIME) == characteristic.UUID {
                        let calendar = NSCalendar.autoupdatingCurrentCalendar() // TODO: 用这个日历是否总是对
                        calendar.timeZone = NSTimeZone(name: "UTC")!
                        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond, fromDate: NSDate())
                        let bytes: [UInt8] = [UInt8(components.year & 0xFF), UInt8((components.year & 0xFF00) >> 8), UInt8(components.month), UInt8(components.day), UInt8(components.hour), UInt8(components.minute), UInt8(components.second)]
//                        println(bytes)
                        peripheral.writeValue(NSData(bytes: bytes, length: bytes.count), forCharacteristic: characteristic, type: .WithResponse)
                        peripheral.readValueForCharacteristic(characteristic)
                    }
                }
            default:
                Log("🔵 未知服务 \(service.UUID)")
            }
        } else {
            central.cancelPeripheralConnection(peripheral)
        }
        oadHelper?.oadHandleEvent(peripheral, event: BLEManagerState.CharacteristicDiscovered, eventData: service, error: error)
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if error == nil {
            switch characteristic.UUID {
            case CBUUID(string: kCharacteristicUUID):
                if peripheral.identifier.UUIDString != defaultDevice() { // 强退 TODO: 待优化
                    central.cancelPeripheralConnection(peripheral)
                    return
                }
                reconnectCount = 0 // 取到数据才算一次完整的重连成功
                dataSource?.onUpdateTemperature(calculateTemperature(characteristic.value), peripheral: peripheral)
            case CBUUID(string: BLE_DATE_TIME):
                println("\(characteristic.UUID)")
            default:
                Log("🔵 未知特性 \(characteristic.UUID)")
            }
        } else {
            central.cancelPeripheralConnection(peripheral)
        }
        oadHelper?.oadHandleEvent(peripheral, event: BLEManagerState.DataReceived, eventData: characteristic, error: error)
    }
    
    ///////////////////////////////////////
    //           OAD support             //
    ///////////////////////////////////////
    func oadStatusUpdate(status: OADStatus, info: String?, progress: UInt8, peripheral: CBPeripheral?) {
        // FIXME: multiple OADHandlers support
        oadSource?.onUpdateOADInfo(status, info: info, progress: progress)
    }
    
    func oadInit() {
        // FIXME: multiple OADHandlers support
        oadHelper = iDo1OADHandler.sharedManager()
        oadHelper?.delegate = self
    }
    
    func oadPrepare(peripheral: CBPeripheral) {
        oadHelper?.oadPrepare(peripheral)
    }
    
    func oadDoUpdate(peripheral: CBPeripheral) {
        oadHelper?.oadDoUpdate(peripheral)
    }
}
