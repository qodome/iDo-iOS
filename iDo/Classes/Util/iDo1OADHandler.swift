//
//  Copyright (c) 2015年 NY. All rights reserved.
//

enum IDO1_QUERY_FLAG: Int {
    case DiscoverService
    case ReadModelName
    case ReadFirmwareVersion
    case WriteIdentify
    case WriteBlock
    case Timeout
}

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
    
    var delegate: OADHandlerDelegate?
    var queryFlag: IDO1_QUERY_FLAG?
    var p: CBPeripheral?
    var liveImgType: IDO1_IMG_TYPE?
    var liveImgVer: String?
    var candImgVerA: String?
    var candImgVerB: String?
    var candImgBuf: NSData?
    var workingThread: NSThread?
    var switchToWrite: UInt?
    var writeIdx: UInt16?
    var threadLock: NSLock?
    var oadStatus: OADStatus = .OADNotAvailable
    var blockCntDown: UInt8 = 0
    let totalBlockNumber: UInt16 = 0x1E80;
    let bleQueryTimeout: Int64 = 30 * Int64(NSEC_PER_SEC)
    
    // MARK: - 💖 生命周期 (Lifecycle)
    class func sharedManager() -> OADHandler {
        struct Singleton {
            static var predicate: dispatch_once_t = 0
            static var instance: OADHandler? = nil
        }
        dispatch_once(&Singleton.predicate, {
            Singleton.instance = iDo1OADHandler()
            println("instance")
        })
        return Singleton.instance!
    }
    
    override init() {
        super.init()
        
        candImgVerA = nil
        candImgVerB = nil
        switchToWrite = 0
        threadLock = NSLock()
        
        // FIXME: check and initialize latest firmware version here!

        
        // Temporary code
        candImgVerA = "33A"
        candImgVerB = "33B"
        oadStatus = .OADAvailable
        // Temporary code
    }
    
    func doTask() {
        var ptr: UnsafePointer<UInt8>?
        var bytes = [UInt8](count: 18, repeatedValue: 0)
        var sleepPeriod: UInt32 = 18000
        
        println("iDo1OAD task started")
        
        // Waiting for UI to wakup us
        while true {
            threadLock?.lock()
            if switchToWrite != 0 {
                threadLock?.unlock()
                break
            }
            threadLock?.unlock()
            sleep(1)
        }
        
        // The main OAD loop
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
                ptr = UnsafePointer<UInt8>(candImgBuf!.bytes);
                let offset = Int(16) * Int(nextBlockIdx!)
                ptr = ptr! + offset
                
                for var idx = 0; idx < 16; idx++ {
                    bytes[idx + 2] = ptr![idx]
                }
                bytes[0] = UInt8(nextBlockIdx! & 0xFF)
                bytes[1] = UInt8((nextBlockIdx! & 0xFF00) >> 8)
                
                BLEUtils.writeCharacteristic(p!, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_BLOCK, data: NSData(bytes: bytes, length: 18), type: CBCharacteristicWriteType.WithoutResponse)

                if nextBlockIdx! % 78 == 0 {
                    delegate?.oadStatusUpdate(OADStatus.OADProgressUpdate, info: nil, progress: UInt8(nextBlockIdx! / 78), peripheral: nil)
                    println("Update percent: " + String(UInt8(nextBlockIdx! / 78)))
                }
                
                usleep(sleepPeriod)
            } else {
                sleep(1)
            }
        }
    }
    
    // FIXME: do the image file download and initialize buffer
    func oadGetImageBuffer() -> Bool {
        var imageName: String
        
        candImgBuf = nil
        
        if liveImgType == .A {
            imageName = candImgVerB! + ".bin"
        } else {
            imageName = candImgVerA! + ".bin"
        }
        
        var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        var documentsDirectory : String;
        documentsDirectory = paths[0] as String
        var fileManager: NSFileManager = NSFileManager()
        var fileList: NSArray = fileManager.contentsOfDirectoryAtPath(documentsDirectory, error: nil)!
        var filesStr: NSMutableString = NSMutableString(string: "Files in Documents folder \n")
        for s in fileList {
            if imageName == s as NSString {
                candImgBuf = NSData.dataWithContentsOfMappedFile(documentsDirectory.stringByAppendingPathComponent(imageName)) as? NSData
                break
            }
        }
        
        if candImgBuf == nil {
            println("Error: cannot get " + imageName)
            return false
        }
        return true
    }
    
    
    func oadPrepare(peripheral: CBPeripheral) {
        if oadStatus == .OADNotAvailable {
            delegate?.oadStatusUpdate(oadStatus, info: nil, progress: 0, peripheral: peripheral)
        } else {
            oadStatus = .OADAvailable
            println("iDo1OADHandler start check firmware version")
            peripheral.discoverServices([CBUUID(string: BLE_DEVICE_INFORMATION), CBUUID(string: IDO1_OAD_SERVICE)])
            queryFlag = .DiscoverService
            
            // Should be able to query current firmware version etc. within 30 seconds
            var time = dispatch_time(DISPATCH_TIME_NOW, bleQueryTimeout)
            dispatch_after(time, dispatch_get_main_queue(), {
                if self.oadStatus == .OADAvailable {
                    self.queryFlag = .Timeout
                    self.oadStatus = .OADNotSupported
                    self.delegate?.oadStatusUpdate(self.oadStatus, info: nil, progress: 0, peripheral: peripheral)
                    println("oadPrepare timeout!")
                }
            });
        }
    }
    
    func oadHandleEvent(peripheral: CBPeripheral, event: BLEManagerState, eventData: AnyObject!, error: NSError!) {
        if event == BLEManagerState.ServiceDiscovered {
            println("iDo1OADHandler got service discovered notify")
            if error == nil {
                if queryFlag == .DiscoverService {
                    for service in peripheral.services as [CBService] {
                        switch service.UUID {
                        case CBUUID(string: BLE_DEVICE_INFORMATION):
                            peripheral.discoverCharacteristics([CBUUID(string: BLE_MODEL_NUMBER_STRING), CBUUID(string: BLE_FIRMWARE_REVISION_STRING)], forService: service)
                        case CBUUID(string: IDO1_OAD_SERVICE):
                            peripheral.discoverCharacteristics([CBUUID(string: IDO1_OAD_IDENTIFY), CBUUID(string: IDO1_OAD_BLOCK)], forService: service)
                        default:
                            continue
                        }
                    }
                }
            } else {
                println("error in service discovery")
            }
        } else if event == BLEManagerState.CharacteristicDiscovered {
            println("iDo1OADHandler got char discovered notify")
            if error == nil {
                if queryFlag == .DiscoverService {
                    switch eventData.UUID {
                    case CBUUID(string: BLE_DEVICE_INFORMATION):
                        for characteristic in eventData.characteristics as [CBCharacteristic] {
                            if CBUUID(string: BLE_MODEL_NUMBER_STRING) == characteristic.UUID {
                                println("request read model number")
                                peripheral.readValueForCharacteristic(characteristic)
                                queryFlag = .ReadModelName
                                break
                            }
                        }
                    default:
                        return
                    }
                }
            } else {
                println("error in char discovery")
            }
        } else if event == BLEManagerState.DataReceived {
            //println("iDo1OADHandler got incoming data")
            if error == nil {
                if queryFlag == .ReadModelName {
                    if eventData.UUID == CBUUID(string: BLE_MODEL_NUMBER_STRING) {
                        var bytes = UnsafeMutablePointer<CChar>.alloc(7)
                        memcpy(bytes, eventData.value!.bytes, 6)
                        bytes[6] = 0
                        
                        if String.fromCString(bytes) == "ID14TB" {
                            println("Identified")
                            BLEUtils.readCharacteristic(peripheral, sUUID: BLE_DEVICE_INFORMATION, cUUID: BLE_FIRMWARE_REVISION_STRING)
                            queryFlag = .ReadFirmwareVersion
                        } else {
                            println("Unknown model name: " + String.fromCString(bytes)!)
                            oadStatus = .OADNotSupported
                            delegate?.oadStatusUpdate(oadStatus, info: nil, progress: 0, peripheral: peripheral)
                        }
                    }
                } else if queryFlag == .ReadFirmwareVersion {
                    if eventData.UUID == CBUUID(string: BLE_FIRMWARE_REVISION_STRING) {
                        var bytes = UnsafeMutablePointer<CChar>.alloc(4)
                        memcpy(bytes, eventData.value!.bytes + 6, 4)
                        bytes[3] = 0
                        
                        liveImgVer = String.fromCString(bytes)
                        println("Image version: " + liveImgVer!)
                        
                        memcpy(bytes, eventData.value!.bytes + 8, 2)
                        bytes[1] = 0
                        println("Image type: " + String.fromCString(bytes)!)
                        
                        if oadStatus != .OADConfirmResult {
                            if String.fromCString(bytes) == "A" {
                                liveImgType = .A
                            } else {
                                liveImgType = .B
                            }
                            
                            if liveImgVer != candImgVerA && liveImgVer != candImgVerB {
                                oadStatus = .OADReady
                            } else {
                                oadStatus = .OADAlreadyLatest
                            }
                            delegate?.oadStatusUpdate(oadStatus, info: nil, progress: 0, peripheral: peripheral)
                        } else {
                            // Check the OAD result
                            if (String.fromCString(bytes) == "A" && liveImgType == .B) ||
                                (String.fromCString(bytes) == "B" && liveImgType == .A) {
                                println("OAD success")
                                oadStatus = .OADSuccess
                            } else {
                                println("OAD failed")
                                oadStatus = .OADFailed
                            }
                            delegate?.oadStatusUpdate(oadStatus, info: nil, progress: 0, peripheral: peripheral)
                        }
                    }
                } else if queryFlag == .WriteIdentify {
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
                        oadStatus = .OADProgressUpdate
                    } else if eventData.UUID == CBUUID(string: IDO1_OAD_IDENTIFY) {
                        var ptr: UnsafePointer<UInt8>?
                        // Write Image Identify UUID
                        
                        ptr = UnsafePointer<UInt8>(candImgBuf!.bytes);
                        ptr = ptr! + 4
                        
                        BLEUtils.writeCharacteristic(peripheral, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_IDENTIFY, data: NSData(bytes: ptr!, length: 8), type: CBCharacteristicWriteType.WithResponse)
                    }
                }
            } else {
                println("error in data")
            }
        } else if event == BLEManagerState.Disconnected {
            if writeIdx >= totalBlockNumber && oadStatus == .OADProgressUpdate {
                println("Device disconnected after OAD")
                oadStatus = .OADConfirmResult
                delegate?.oadStatusUpdate(oadStatus, info: nil, progress: 0, peripheral: peripheral)
            }
        } else if event == BLEManagerState.Connected {
            if oadStatus == .OADConfirmResult {
                println("Confirm OAD result")
                peripheral.discoverServices([CBUUID(string: BLE_DEVICE_INFORMATION)])
                queryFlag = .DiscoverService
            }
        }
    }
    
    func oadDoUpdate(peripheral: CBPeripheral) {
        var bytes = [UInt8](count: 8, repeatedValue: 0xFF)
        
        if oadStatus == .OADReady {
            println("OAD Start!")
            if oadGetImageBuffer() == false {
                oadStatus = .OADNotAvailable
                delegate?.oadStatusUpdate(oadStatus, info: nil, progress: 0, peripheral: peripheral)
                return
            }
            p = peripheral
            BLEUtils.setNotificationForCharacteristic(peripheral, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_IDENTIFY, enable: true)
            BLEUtils.setNotificationForCharacteristic(peripheral, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_BLOCK, enable: true)
            
            BLEUtils.writeCharacteristic(peripheral, sUUID: IDO1_OAD_SERVICE, cUUID: IDO1_OAD_IDENTIFY, data: NSData(bytes: bytes, length: 8), type: CBCharacteristicWriteType.WithResponse)
            
            queryFlag = .WriteIdentify
            
            // Start working thread
            workingThread = NSThread(target: self, selector: "doTask", object: nil)
            workingThread?.start()
            
            // Should be able to query current firmware version etc. within 30 seconds
            var time = dispatch_time(DISPATCH_TIME_NOW, bleQueryTimeout)
            dispatch_after(time, dispatch_get_main_queue(), {
                if self.oadStatus == .OADReady {
                    self.queryFlag = .Timeout
                    self.oadStatus = .OADNotSupported
                    self.delegate?.oadStatusUpdate(self.oadStatus, info: nil, progress: 0, peripheral: peripheral)
                    println("oadPrepare timeout!")
                }
            });
        } else {
            oadStatus = .OADFailed
            delegate?.oadStatusUpdate(oadStatus, info: nil, progress: 0, peripheral: peripheral)
        }
    }
}
