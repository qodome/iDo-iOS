//
//  Copyright (c) 2015年 NY. All rights reserved.
//

enum IDO1_IMG_TYPE: Int {
    case A
    case B
}

extension UInt {
    init?(_ string: String, radix: UInt) {
        let digits = "0123456789abcdefghijklmnopqrstuvwxyz"
        var result = UInt(0)
        for digit in string.lowercaseString {
            if let range = digits.rangeOfString(String(digit)) {
                let val = UInt(distance(digits.startIndex, range.startIndex))
                if val >= radix {
                    return nil
                }
                result = result * radix + val
            } else {
                return nil
            }
        }
        self = result
    }
}

class iDo1OADHandler: NSObject, OADHandler {
    
    private var candImgBuf: NSData?
    private var switchToWrite: UInt?
    private var writeIdx: UInt16?
    private var threadLock: NSLock?
    private var liveImgType: IDO1_IMG_TYPE?
    private var newPeripheral: CBPeripheral?
    private var SLEEP_BREAKER = 1
    private var identifyCnt = 0
    private var lastPercent: UInt8 = 0
    private var oadStatus = OADStatus.NotAvailable
    private var blockCntDown = 0
    private let totalBlockNumber: UInt16 = 0x1E80;
//    private let bleQueryTimeout: Int64 = 30 * Int64(NSEC_PER_SEC)
    
    class var sharedManager: OADHandler {
        struct Singleton {
            static let instance = iDo1OADHandler()
        }
        return Singleton.instance
    }
    
    // MARK: - 💖 生命周期 (Lifecycle)
    private override init() {
        super.init()
        switchToWrite = 0
        threadLock = NSLock()
    }
    
    func oadHandleEvent(peripheral: CBPeripheral, event: BLEManagerState, eventData: AnyObject!) {
        switch event {
        case BLEManagerState.ServiceDiscovered:
            println("iDo1OADHandler got service discovered notify")
            if oadStatus == .Available {
                for service in peripheral.services as [CBService] {
                    switch service.UUID.UUIDString {
                    case IDO1_OAD_SERVICE:
                        peripheral.discoverCharacteristics([CBUUID(string: IDO1_OAD_IDENTIFY), CBUUID(string: IDO1_OAD_BLOCK)], forService: service)
                    default:
                        continue
                    }
                }
            }
        case BLEManagerState.CharacteristicDiscovered:
            println("iDo1OADHandler got char discovered notify")
            if oadStatus == .Available {
                switch eventData.UUID {
                case CBUUID(string: IDO1_OAD_SERVICE):
                    for characteristic in eventData.characteristics as [CBCharacteristic] {
                        switch characteristic.UUID.UUIDString {
                        case IDO1_OAD_IDENTIFY:
                            oadStatus = .Ready
                            break
                        case IDO1_OAD_BLOCK:
                            oadStatus = .Ready
                            break
                        default:
                            continue
                        }
                    }
                default:
                    return
                }
            }
        case BLEManagerState.DataReceived:
            //println("iDo1OADHandler got incoming data")
            if oadStatus == .ProgressUpdate {
                if eventData.UUID == CBUUID(string: IDO1_OAD_BLOCK) {
                    var bytes = UnsafeMutablePointer<UInt8>.alloc(2)
                    memcpy(bytes, eventData.value!.bytes, 2)
                    var idx: UInt16 = UInt16(bytes[1]) << 8 | UInt16(bytes[0])
                    println("Got block notification " + String(idx))
                    threadLock?.lock()
                    switchToWrite = 1
                    writeIdx = idx
                    blockCntDown = 10
                    threadLock?.unlock()
                } else if eventData.UUID == CBUUID(string: IDO1_OAD_IDENTIFY) {
                    var ptr: UnsafePointer<UInt8>?
                    // Write Image Identify UUID
                    
                    println("Got identify notification")
                    identifyCnt++
                    if identifyCnt > 5 {
                        // Tell update worker this firmware image does not match!
                        oadStatus = .NotSupported
                        threadLock?.lock()
                        switchToWrite = 1
                        threadLock?.unlock()
                    }
                    
                    ptr = UnsafePointer<UInt8>(candImgBuf!.bytes);
                    ptr = ptr! + 4
                    
                    BLEUtils.writeCharacteristic(peripheral, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_IDENTIFY, data: NSData(bytes: ptr!, length: 8), type: .WithResponse)
                }
            } else if oadStatus == .ConfirmResult {
                if eventData.UUID == CBUUID(string: BLE_FIRMWARE_REVISION_STRING) {
                    var bytes = UnsafeMutablePointer<CChar>.alloc(4)
                    memcpy(bytes, eventData.value!.bytes + 6, 4)
                    bytes[3] = 0
                    
                    println("Image version: " + String.fromCString(bytes)!)
                    
                    memcpy(bytes, eventData.value!.bytes + 8, 2)
                    bytes[1] = 0
                    
                    // Check the OAD result
                    if (String.fromCString(bytes) == "A" && liveImgType == .B) ||
                        (String.fromCString(bytes) == "B" && liveImgType == .A) {
                            println("OAD success")
                            oadStatus = .Success
                    } else {
                        println("OAD failed")
                        oadStatus = .Failed
                    }
                }
            }
        case BLEManagerState.Disconnected:
            if writeIdx >= totalBlockNumber && oadStatus == .ProgressUpdate {
                println("Device disconnected after OAD")
                oadStatus = .Reconnect
            }
        case BLEManagerState.Connected:
            if oadStatus == .Reconnect {
                println("Confirm OAD result")
                oadStatus = .ConfirmResult
                newPeripheral = peripheral
            }
        case BLEManagerState.Fail:
            if oadStatus == .Reconnect {
                println("Confirm OAD result")
                oadStatus = .Failed
            }
        default: break
        }
    }
    
    func oadDoUpdate(peripheral: CBPeripheral, path: String, progress: M13ProgressViewPie) -> OADStatus {
        var ptr: UnsafePointer<UInt8>?
        var bytes = [UInt8](count: 18, repeatedValue: 0)
        var sleepPeriod: UInt32 = 18000
        var sleepCnt = 0
        
        progress.setProgress(0.0, animated: true)
        
        // Setup BLEManager handler to receive packets
        identifyCnt = 0
        oadStatus = .Available
        
        BLEManager.sharedManager.oadHelper = self
        // Read file
        candImgBuf = NSData.dataWithContentsOfMappedFile(path) as? NSData
        if candImgBuf == nil {
            println("Error: cannot get " + path)
            BLEManager.sharedManager.oadHelper = nil
            oadStatus = .NotAvailable
            progress.performAction(M13ProgressViewActionFailure, animated: true)
            return oadStatus
        }
        let fn = path.lastPathComponent
        if fn.rangeOfString("A.bin", options: .BackwardsSearch) != nil {
            liveImgType = .B
        } else {
            liveImgType = .A
        }
        // Check OAD service
        var oadCharCnt = 0
        println("ccccc")
        for service in peripheral.services as [CBService] {
            println("ccccc1")
            switch service.UUID.UUIDString {
            case IDO1_OAD_SERVICE:
                println("ccccc2")
                for char in service.characteristics as [CBCharacteristic] {
                    println("ccccc3")
                    switch char.UUID.UUIDString {
                    case IDO1_OAD_IDENTIFY:
                        oadCharCnt++
                    case IDO1_OAD_BLOCK:
                        oadCharCnt++
                    default:
                        continue
                    }
                }
            default:
                continue
            }
        }
        println("ddddd")
        if oadCharCnt < 2 {
            // Discover OAD service
            println("iDo1OADHandler start service discovery")
            peripheral.discoverServices([CBUUID(string: IDO1_OAD_SERVICE)])
            
            sleepCnt = 0
            while oadStatus == .Available  {
                sleep(1)
                sleepCnt++
                if SLEEP_BREAKER == 1 && sleepCnt > 30 {
                    break
                }
            }
        }
        if oadStatus != .Ready {
            println("OAD service discovery failed")
            BLEManager.sharedManager.oadHelper = nil
            oadStatus = .NotSupported
            progress.performAction(M13ProgressViewActionFailure, animated: true)
            return oadStatus
        }
        
        println("OAD begin!")
        oadStatus = .ProgressUpdate
        
        BLEUtils.setNotificationForCharacteristic(peripheral, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_IDENTIFY, enable: true)
        BLEUtils.setNotificationForCharacteristic(peripheral, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_BLOCK, enable: true)
        
        ptr = UnsafePointer<UInt8>(candImgBuf!.bytes);
        ptr = ptr! + 4
        
        BLEUtils.writeCharacteristic(peripheral, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_IDENTIFY, data: NSData(bytes: ptr!, length: 8), type: .WithResponse)
        
        // Waiting for UI to wakup us
        sleepCnt = 0
        while true {
            threadLock?.lock()
            if switchToWrite != 0 {
                threadLock?.unlock()
                break
            }
            threadLock?.unlock()
            // TODO add disconnect check
            sleep(1)
            sleepCnt++
            if SLEEP_BREAKER == 1 && sleepCnt > 60 {
                println("OAD timeout1")
                BLEManager.sharedManager.oadHelper = nil
                oadStatus = .NotSupported
                progress.performAction(M13ProgressViewActionFailure, animated: true)
                return oadStatus
            }
        }
        
        if oadStatus == .NotSupported {
            println("OAD image does not match")
            BLEManager.sharedManager.oadHelper = nil
            progress.performAction(M13ProgressViewActionFailure, animated: true)
            return oadStatus
        }
        
        // The main OAD loop
        sleepCnt = 0
        while true {
            var nextBlockIdx: UInt16?
            
            threadLock?.lock()
            nextBlockIdx = writeIdx
            if nextBlockIdx < totalBlockNumber {
                writeIdx? += 1
            }
            if blockCntDown > 0 {
                blockCntDown--
                sleepPeriod = 180000
            } else {
                sleepPeriod = 18000
            }
            threadLock?.unlock()
            
            if nextBlockIdx < totalBlockNumber {
                sleepCnt = 0
                ptr = UnsafePointer<UInt8>(candImgBuf!.bytes);
                let offset = Int(16) * Int(nextBlockIdx!)
                ptr = ptr! + offset
                
                for var idx = 0; idx < 16; idx++ {
                    bytes[idx + 2] = ptr![idx]
                }
                bytes[0] = UInt8(nextBlockIdx! & 0xFF)
                bytes[1] = UInt8((nextBlockIdx! & 0xFF00) >> 8)
                
                BLEUtils.writeCharacteristic(peripheral, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_BLOCK, data: NSData(bytes: bytes, length: 18), type: .WithoutResponse)
                
                if nextBlockIdx! % 78 == 0 {
                    if UInt8(nextBlockIdx! / 78) > lastPercent {
                        println("Update percent: " + String(UInt8(nextBlockIdx! / 78)))
                        progress.setProgress(CGFloat(Float(nextBlockIdx! / 78) / 100.0), animated: true)
                        lastPercent = UInt8(nextBlockIdx! / 78)
                    }
                }
                
                usleep(sleepPeriod)
            } else {
                if oadStatus == .Reconnect || oadStatus == .ConfirmResult {
                    break
                }
                // TODO add disconnect check
                sleep(1)
                sleepCnt++
                if SLEEP_BREAKER == 1 && sleepCnt > 60 {
                    println("OAD timeout2")
                    BLEManager.sharedManager.oadHelper = nil
                    oadStatus = .NotSupported
                    progress.performAction(M13ProgressViewActionFailure, animated: true)
                    return oadStatus
                }
            }
        }
        
        // We shall reconnect to iDo after OAD reset
        sleepCnt = 0
        while oadStatus == .Reconnect {
            sleep(1)
            sleepCnt++
            if SLEEP_BREAKER == 1 && sleepCnt > 20 {
                println("Failed to reconnect to iDo after OAD")
                BLEManager.sharedManager.oadHelper = nil
                oadStatus = .NotSupported
                progress.performAction(M13ProgressViewActionFailure, animated: true)
                return oadStatus
            }
        }
        
        if oadStatus != .ConfirmResult {
            println("Failed to reconnect to iDo")
            BLEManager.sharedManager.oadHelper = nil
            oadStatus = .NotSupported
            progress.performAction(M13ProgressViewActionFailure, animated: true)
            return oadStatus
        }
        
        // Wait for main thread to do the service discovery
        sleep(2)
        
        BLEUtils.readCharacteristic(newPeripheral!, sUUID: BLE_DEVICE_INFORMATION, cUUID: BLE_FIRMWARE_REVISION_STRING)
        
        sleepCnt = 0
        while oadStatus == .ConfirmResult {
            sleep(1)
            sleepCnt++
            if SLEEP_BREAKER == 1 && sleepCnt > 20 {
                println("Failed to check iDo version after OAD")
                BLEManager.sharedManager.oadHelper = nil
                oadStatus = .NotSupported
                progress.performAction(M13ProgressViewActionFailure, animated: true)
                return oadStatus
            }
        }
        
        if oadStatus == .Success {
            progress.performAction(M13ProgressViewActionSuccess, animated: true)
        } else {
            progress.performAction(M13ProgressViewActionFailure, animated: true)
        }
        
        return oadStatus
    }
}
