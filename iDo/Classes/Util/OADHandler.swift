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

protocol OADHandler {
    func oadHandleEvent(peripheral: CBPeripheral, event: BLEManagerEvent, eventData: AnyObject!)
    
    func oadDoUpdate(peripheral: CBPeripheral, path: String, progress: M13ProgressViewPie) -> OADState
}
