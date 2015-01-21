//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class BLEUtils: NSObject {
    
    class func writeCharacteristic(peripheral: CBPeripheral, sUUID: String, cUUID: String, data: NSData, type: CBCharacteristicWriteType) {
        if peripheral.services != nil {
            for service in peripheral.services as [CBService] {
                switch service.UUID {
                case CBUUID(string: sUUID):
                    for char in service.characteristics as [CBCharacteristic] {
                        switch char.UUID {
                        case CBUUID(string: cUUID):
                            peripheral.writeValue(data, forCharacteristic: char, type: type)
                        default:
                            continue
                        }
                    }
                default:
                    continue
                }
            }
        }
    }
    
    class func readCharacteristic(peripheral: CBPeripheral, sUUID: String, cUUID: String) {
        if peripheral.services != nil {
            for service in peripheral.services as [CBService] {
                switch service.UUID {
                case CBUUID(string: sUUID):
                    for char in service.characteristics as [CBCharacteristic] {
                        switch char.UUID {
                        case CBUUID(string: cUUID):
                            peripheral.readValueForCharacteristic(char)
                        default:
                            continue
                        }
                    }
                default:
                    continue
                }
            }
        }
    }
    
    class func setNotificationForCharacteristic(peripheral: CBPeripheral, sUUID: String, cUUID: String, enable: Bool) {
        if peripheral.services != nil {
            for service in peripheral.services as [CBService] {
                switch service.UUID {
                case CBUUID(string: sUUID):
                    for char in service.characteristics as [CBCharacteristic] {
                        switch char.UUID {
                        case CBUUID(string: cUUID):
                            peripheral.setNotifyValue(enable, forCharacteristic: char)
                        default:
                            continue
                        }
                    }
                default:
                    continue
                }
            }
        }
    }
}
