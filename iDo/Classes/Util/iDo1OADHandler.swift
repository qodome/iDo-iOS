//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class iDo1OADHandler: OADHandler {
    
    let IDO1_OAD_SERVICE = "F000FFC0-0451-4000-B000-000000000000"
    let IDO1_OAD_IDENTIFY = "F000FFC1-0451-4000-B000-000000000000"
    let IDO1_OAD_BLOCK = "F000FFC2-0451-4000-B000-000000000000"
    
    private var data: NSData!
    private var switchToWrite = false
    private var writeIdx = 0
    private var threadLock: NSLock?
    private var newPeripheral: CBPeripheral!
    private var SLEEP_BREAKER = 1
    private var identifyCnt = 0
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
        blockCount = 7808 // 0x1E80
        threadLock = NSLock()
    }
    
    override func oadHandleEvent(peripheral: CBPeripheral, event: BLEManagerEvent) {
        switch event {
        case BLEManagerEvent.ServiceDiscovered:
            if state == .Available {
                for service in peripheral.services as [CBService] {
                    if service.UUID.UUIDString == IDO1_OAD_SERVICE {
                        peripheral.discoverCharacteristics([CBUUID(string: IDO1_OAD_IDENTIFY), CBUUID(string: IDO1_OAD_BLOCK)], forService: service)
                        break
                    }
                }
            }
        case BLEManagerEvent.Disconnected:
            if writeIdx >= blockCount && state == .ProgressUpdate {
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
                var buffer = [UInt8](count: 8, repeatedValue: 0)
                data.getBytes(&buffer, range: NSMakeRange(4, 8))
                peripheral.writeValue(NSData(bytes: buffer, length: 8), forCharacteristic: characteristicId, type: .WithResponse)
            } else if characteristic.UUID.UUIDString == IDO1_OAD_BLOCK {
                var buffer = [UInt8](count: 2, repeatedValue: 0)
                characteristic.value.getBytes(&buffer, length: 2)
                threadLock?.lock()
                switchToWrite = true
                writeIdx = Int(getInt8(buffer[1])) << 8 | Int(getInt8(buffer[0]))
                blockCntDown = 10
                threadLock?.unlock()
                println("Got block notification \(writeIdx)")
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
    
    override func update(peripheral: CBPeripheral, data: NSData, progress: M13ProgressHUD) -> OADState {
        var sleepPeriod: UInt32 = 18000
        var sleepCnt = 0
        // Setup BLEManager handler to receive packets
        identifyCnt = 0
        state = .Available
        BLEManager.sharedManager.oadHelper = self
        self.data = data
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
            return getState(.NotSupported, progress: progress)
        }
        Log("⭕️ OAD begin!")
        state = .ProgressUpdate
        peripheral.setNotifyValue(true, forCharacteristic: characteristicId)
        peripheral.setNotifyValue(true, forCharacteristic: characteristicBlock)
        var buffer = [UInt8](count: 8, repeatedValue: 0) // 先写8位
        data.getBytes(&buffer, range: NSMakeRange(4, 8))
        peripheral.writeValue(NSData(bytes: buffer, length: 8), forCharacteristic: characteristicId, type: .WithResponse)
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
                return getState(.NotSupported, progress: progress)
            }
        }
        if state == .NotSupported {
            println("🆎 OAD image does not match")
            return getState(.NotSupported, progress: progress)
        }
        // The main OAD loop
        sleepCnt = 0
        while true {
            threadLock?.lock()
            var next = writeIdx
            if next < blockCount {
                writeIdx++
            }
            if blockCntDown > 0 {
                blockCntDown--
                sleepPeriod = 180000
            } else {
                sleepPeriod = 18000
            }
            threadLock?.unlock()
            if next < blockCount {
                sleepCnt = 0
                var buffer = [UInt8](count: 16, repeatedValue: 0) // 每次16位数据
                data.getBytes(&buffer, range: NSMakeRange(16 * next, 16))
                peripheral.writeValue(NSData(bytes: [UInt8(next & 0xFF), UInt8((next & 0xFF00) >> 8)] + buffer, length: 18), forCharacteristic: characteristicBlock, type: .WithoutResponse)
                if next % 78 == 0 {
                    let percent = next / 78
                    progress.setProgress(CGFloat(percent) / 100, animated: true)
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
                    return getState(.NotSupported, progress: progress)
                }
            }
        }
        // 更新完成后重连
        sleepCnt = 0
        while state == .Reconnect {
            sleep(1)
            sleepCnt++
            if SLEEP_BREAKER == 1 && sleepCnt > 20 {
                println("Failed to reconnect to iDo after OAD")
                return getState(.NotSupported, progress: progress)
            }
        }
        if state != .ConfirmResult {
            println("Failed to reconnect to iDo")
            return getState(.NotSupported, progress: progress)
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
                return getState(.NotSupported, progress: progress)
            }
        }
        return getState(state, progress: progress)
    }
    
    private func getState(state: OADState, progress: M13ProgressHUD) -> OADState {
        self.state = state
        if state == .NotSupported {
            BLEManager.sharedManager.oadHelper = nil
        }
        delay(0.5 + Double(progress.animationDuration)) {
            progress.performAction(state == .Success ? M13ProgressViewActionSuccess : M13ProgressViewActionFailure, animated: true)
            delay(1 + Double(progress.animationDuration)) {
                progress.hide(true)
                progress.performAction(M13ProgressViewActionNone, animated: false)
            }
        }
        return state
    }
}
