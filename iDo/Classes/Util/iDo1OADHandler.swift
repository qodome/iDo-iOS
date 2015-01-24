//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class iDo1OADHandler: OADHandler {
    
    let IDO1_OAD_SERVICE = "F000FFC0-0451-4000-B000-000000000000"
    let IDO1_OAD_IDENTIFY = "F000FFC1-0451-4000-B000-000000000000"
    let IDO1_OAD_BLOCK = "F000FFC2-0451-4000-B000-000000000000"
    
    let totalBlockNumber = 0x1E80
    
    private var candImgBuf: NSData!
    private var switchToWrite = false
    private var writeIdx = 0
    private var threadLock: NSLock?
    private var newPeripheral: CBPeripheral!
    private var SLEEP_BREAKER = 1
    private var identifyCnt = 0
    private var lastPercent = 0
    private var state = OADState.NotAvailable
    private var blockCntDown = 0
    
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
    
    override func oadHandleEvent(peripheral: CBPeripheral, event: BLEManagerEvent) {
        switch event {
        case BLEManagerEvent.ServiceDiscovered:
            println("iDo1OADHandler got service discovered notify")
            if state == .Available {
                for service in peripheral.services as [CBService] {
                    println("haha \(service)")
                    if service.UUID.UUIDString == IDO1_OAD_SERVICE {
                        peripheral.discoverCharacteristics([CBUUID(string: IDO1_OAD_IDENTIFY), CBUUID(string: IDO1_OAD_BLOCK)], forService: service)
                        break
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
    
    override func onCharacteristicDiscovered(peripheral: CBPeripheral, service: CBService) {
        println("iDo1OADHandler got char discovered notify")
        if state == .Available {
            if service.UUID.UUIDString == IDO1_OAD_SERVICE {
                for characteristic in service.characteristics as [CBCharacteristic] {
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
    }
    
    override func onUpdateValue(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        if state == .ProgressUpdate {
            if characteristic.UUID.UUIDString == IDO1_OAD_IDENTIFY {
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
            } else if characteristic.UUID.UUIDString == IDO1_OAD_BLOCK {
                var bytes = [UInt8](count: 2, repeatedValue: 0)
                characteristic.value.getBytes(&bytes, length: bytes.count)
                //                    var bytes = UnsafeMutablePointer<UInt8>.alloc(2)
                //                    memcpy(bytes, eventData.value!.bytes, 2)
                let idx = Int(getInt8(bytes[1])) << 8 | Int(getInt8(bytes[0]))
                println("Got block notification \(idx)")
                threadLock?.lock()
                switchToWrite = true
                writeIdx = idx
                blockCntDown = 10
                threadLock?.unlock()
            }
        } else if state == .ConfirmResult {
            if characteristic.UUID.UUIDString == BLE_FIRMWARE_REVISION_STRING {
                let revision = getString(characteristic.value)
                if getString(characteristic.value) == revision {
                    state = .Success
                } else {
                    state = .Failed
                }
            }
        }
    }
    
    override func update(peripheral: CBPeripheral, data: NSData, progress: M13ProgressView) -> OADState {
        var ptr: UnsafePointer<UInt8>?
        var sleepPeriod: UInt32 = 18000
        var sleepCnt = 0
        progress.setProgress(0.0, animated: true) // 进度条从0开始
        // Setup BLEManager handler to receive packets
        identifyCnt = 0
        state = .Available
        BLEManager.sharedManager.oadHelper = self
        candImgBuf = data
        Log("⭕️ iDo1OADHandler start service discovery")
        peripheral.discoverServices([CBUUID(string: IDO1_OAD_SERVICE)]) // 发现服务
        
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
        peripheral.writeValue(NSData(bytes: ptr!, length: 8), forCharacteristic: characteristicId, type: .WithResponse) // 先写8位
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
            var nextBlockIdx = 0
            
            threadLock?.lock()
            nextBlockIdx = writeIdx
            if nextBlockIdx < totalBlockNumber {
                writeIdx++
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
                let offset = 16 * nextBlockIdx
                ptr = ptr! + offset
                var bytes = [UInt8](count: 18, repeatedValue: 0) // 18位数据
                bytes[0] = UInt8(nextBlockIdx & 0xFF)
                bytes[1] = UInt8((nextBlockIdx & 0xFF00) >> 8)
                for i in 2..<18 {
                    bytes[i] = ptr![i - 2]
                }
                peripheral.writeValue(NSData(bytes: bytes, length: bytes.count), forCharacteristic: characteristicBlock, type: .WithoutResponse)
                if nextBlockIdx % 78 == 0 {
                    let percent = nextBlockIdx / 78
                    if percent > lastPercent {
                        println("Update percent: \(percent)%")
                        progress.setProgress(CGFloat(percent) / 100, animated: true)
                        lastPercent = percent
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
