//
//  Copyright (c) 2015年 NY. All rights reserved.
//

enum OADState: Int {
    case Available
    case NotAvailable
    case NotSupported
    case AlreadyLatest
    case Ready
    case ProgressUpdate
    case Reconnect
    case ConfirmResult
    case Success
    case Failed
}

class OADHandler: NSObject {
    
    var revision = "" // 目标版本
    var blockCount = 0
    
    func oadHandleEvent(peripheral: CBPeripheral, event: BLEManagerEvent) {}
    
    func onCharacteristicDiscovered(peripheral: CBPeripheral, service: CBService) {}
    
    func onUpdateValue(peripheral: CBPeripheral, characteristic: CBCharacteristic) {}
    
    func update(peripheral: CBPeripheral, data: NSData, progress: M13ProgressHUD) -> OADState {
        return .NotAvailable
    }
}
