//
//  Copyright (c) 2015年 NY. All rights reserved.
//

enum IDO1_IMG_TYPE: Int {
    case A
    case B
}

class iDo1OADHandler: NSObject, OADHandler {
    
    let totalBlockNumber: UInt16 = 0x1E80
    
    private var candImgBuf: NSData!
    private var switchToWrite = false
    private var writeIdx: UInt16?
    private var threadLock: NSLock?
    private var liveImgType: IDO1_IMG_TYPE?
    private var newPeripheral: CBPeripheral!
    private var SLEEP_BREAKER = 1
    private var identifyCnt = 0
    private var lastPercent: UInt8 = 0
    private var state = OADState.NotAvailable
    private var blockCntDown = 0
    
    
    private var service: CBService?
    private var characteristicId: CBCharacteristic?
    private var characteristicBlock: CBCharacteristic?
    
    class var sharedManager: OADHandler {
        struct Singleton {
            static let instance = iDo1OADHandler()
        }
        return Singleton.instance
    }
    
    // MARK: - 💖 生命周期 (Lifecycle)
    private override init() {
        super.init()
        threadLock = NSLock()
    }
    
    func oadHandleEvent(peripheral: CBPeripheral, event: BLEManagerEvent, eventData: AnyObject!) {
        switch event {
        case BLEManagerEvent.ServiceDiscovered:
            println("iDo1OADHandler got service discovered notify")
            if state == .Available {
                for service in peripheral.services as [CBService] {
                    println("haha \(service)")
                    if service.UUID.UUIDString == IDO1_OAD_SERVICE {
                        self.service = service
                        peripheral.discoverCharacteristics([CBUUID(string: IDO1_OAD_IDENTIFY), CBUUID(string: IDO1_OAD_BLOCK)], forService: service)
                        break
                    }
                }
            }
        case BLEManagerEvent.CharacteristicDiscovered:
            println("iDo1OADHandler got char discovered notify")
            if state == .Available {
                if (eventData as CBService).UUID.UUIDString == IDO1_OAD_SERVICE {
                    for characteristic in eventData.characteristics as [CBCharacteristic] {
                        if characteristic.UUID.UUIDString == IDO1_OAD_IDENTIFY {
                            characteristicId = characteristic
                            state = .Ready
                        } else if characteristic.UUID.UUIDString == IDO1_OAD_BLOCK {
                            characteristicBlock = characteristic
                            state = .Ready
                        }
                    }
                }
            }
        case BLEManagerEvent.DataReceived:
            if state == .ProgressUpdate {
                if eventData.UUID == CBUUID(string: IDO1_OAD_BLOCK) {
//                    var bytes = [UInt8](count: 2, repeatedValue: 0)
//                    eventData.value!.getBytes(&bytes, length: bytes.count)
                    var bytes = UnsafeMutablePointer<UInt8>.alloc(2)
                    memcpy(bytes, eventData.value!.bytes, 2)
                    var idx: UInt16 = UInt16(bytes[1]) << 8 | UInt16(bytes[0])
                    println("Got block notification \(idx)")
                    threadLock?.lock()
                    switchToWrite = true
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
                        state = .NotSupported
                        threadLock?.lock()
                        switchToWrite = true
                        threadLock?.unlock()
                    }
                    ptr = UnsafePointer<UInt8>(candImgBuf.bytes)
                    ptr = ptr! + 4
                    peripheral.writeValue(NSData(bytes: ptr!, length: 8), forCharacteristic: characteristicId, type: .WithResponse)
                }
            } else if state == .ConfirmResult {
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
                            state = .Success
                    } else {
                        println("OAD failed")
                        state = .Failed
                    }
                }
            }
        case BLEManagerEvent.Disconnected:
            if writeIdx >= totalBlockNumber && state == .ProgressUpdate {
                println("Device disconnected after OAD")
                state = .Reconnect
            }
        case BLEManagerEvent.Connected:
            if state == .Reconnect {
                println("Confirm OAD result")
                state = .ConfirmResult
                newPeripheral = peripheral
            }
        case BLEManagerEvent.Fail:
            if state == .Reconnect {
                println("Confirm OAD result")
                state = .Failed
            }
        default: break
        }
    }
    
    func oadDoUpdate(peripheral: CBPeripheral, path: String, progress: M13ProgressViewPie) -> OADState {
        var ptr: UnsafePointer<UInt8>?
        var bytes = [UInt8](count: 18, repeatedValue: 0)
        var sleepPeriod: UInt32 = 18000
        var sleepCnt = 0
        
        progress.setProgress(0.0, animated: true)
        
        // Setup BLEManager handler to receive packets
        identifyCnt = 0
        state = .Available
        
        BLEManager.sharedManager.oadHelper = self
        // Read file
        let data = NSData.dataWithContentsOfMappedFile(path) as? NSData
        if data == nil {
            println("Error: cannot get " + path)
            BLEManager.sharedManager.oadHelper = nil
            state = .NotAvailable
            progress.performAction(M13ProgressViewActionFailure, animated: true)
            return state
        } else {
            candImgBuf = data!
        }
        if path.lastPathComponent.rangeOfString("A.bin", options: .BackwardsSearch) != nil {
            liveImgType = .B
        } else {
            liveImgType = .A
        }
        // Discover OAD service
        Log("⭕️ iDo1OADHandler start service discovery")
        peripheral.discoverServices([CBUUID(string: IDO1_OAD_SERVICE)])
        
        sleepCnt = 0
        while state == .Available {
            sleep(1)
            sleepCnt++
            if SLEEP_BREAKER == 1 && sleepCnt > 30 {
                break
            }
        }
        if state != .Ready {
            Log("⭕️ OAD service discovery failed")
            BLEManager.sharedManager.oadHelper = nil
            state = .NotSupported
            progress.performAction(M13ProgressViewActionFailure, animated: true)
            return state
        }
        Log("⭕️ OAD begin!")
        state = .ProgressUpdate
        peripheral.setNotifyValue(true, forCharacteristic: characteristicId)
        peripheral.setNotifyValue(true, forCharacteristic: characteristicBlock)
        
        ptr = UnsafePointer<UInt8>(candImgBuf.bytes)
        ptr = ptr! + 4
        peripheral.writeValue(NSData(bytes: ptr!, length: 8), forCharacteristic: characteristicId, type: .WithResponse)
        
        // Waiting for UI to wakup us
        sleepCnt = 0
        while true {
            threadLock?.lock()
            if switchToWrite {
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
                state = .NotSupported
                progress.performAction(M13ProgressViewActionFailure, animated: true)
                return state
            }
        }
        
        if state == .NotSupported {
            println("🆎 OAD image does not match")
            BLEManager.sharedManager.oadHelper = nil
            progress.performAction(M13ProgressViewActionFailure, animated: true)
            return state
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
                ptr = UnsafePointer<UInt8>(candImgBuf.bytes)
                let offset = Int(16) * Int(nextBlockIdx!)
                ptr = ptr! + offset
                
                for idx in 0..<16 {
                    // for var idx = 0; idx < 16; idx++ {
                    bytes[idx + 2] = ptr![idx]
                }
                bytes[0] = UInt8(nextBlockIdx! & 0xFF)
                bytes[1] = UInt8((nextBlockIdx! & 0xFF00) >> 8)
                peripheral.writeValue(NSData(bytes: bytes, length: 18), forCharacteristic: characteristicBlock, type: .WithoutResponse)
                
                if nextBlockIdx! % 78 == 0 {
                    if UInt8(nextBlockIdx! / 78) > lastPercent {
                        println("Update percent: \(UInt8(nextBlockIdx! / 78))%")
                        progress.setProgress(CGFloat(Float(nextBlockIdx! / 78) / 100.0), animated: true)
                        lastPercent = UInt8(nextBlockIdx! / 78)
                    }
                }
                
                usleep(sleepPeriod)
            } else {
                if state == .Reconnect || state == .ConfirmResult {
                    break
                }
                // TODO add disconnect check
                sleep(1)
                sleepCnt++
                if SLEEP_BREAKER == 1 && sleepCnt > 60 {
                    println("OAD timeout2")
                    BLEManager.sharedManager.oadHelper = nil
                    state = .NotSupported
                    progress.performAction(M13ProgressViewActionFailure, animated: true)
                    return state
                }
            }
        }
        // 重连
        sleepCnt = 0
        while state == .Reconnect {
            sleep(1)
            sleepCnt++
            if SLEEP_BREAKER == 1 && sleepCnt > 20 {
                println("Failed to reconnect to iDo after OAD")
                BLEManager.sharedManager.oadHelper = nil
                state = .NotSupported
                progress.performAction(M13ProgressViewActionFailure, animated: true)
                return state
            }
        }
        if state != .ConfirmResult {
            println("Failed to reconnect to iDo")
            BLEManager.sharedManager.oadHelper = nil
            state = .NotSupported
            progress.performAction(M13ProgressViewActionFailure, animated: true)
            return state
        }
        // Wait for main thread to do the service discovery
        sleep(2)
        newPeripheral.readValueForCharacteristic(BLEManager.sharedManager.characteristicFirmware)
        
        sleepCnt = 0
        while state == .ConfirmResult {
            sleep(1)
            sleepCnt++
            if SLEEP_BREAKER == 1 && sleepCnt > 20 {
                println("Failed to check iDo version after OAD")
                BLEManager.sharedManager.oadHelper = nil
                state = .NotSupported
                progress.performAction(M13ProgressViewActionFailure, animated: true)
                return state
            }
        }
        if state == .Success {
            progress.performAction(M13ProgressViewActionSuccess, animated: true)
        } else {
            progress.performAction(M13ProgressViewActionFailure, animated: true)
        }
        return state
    }
}
