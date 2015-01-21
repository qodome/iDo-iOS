//
//  Copyright (c) 2015年 NY. All rights reserved.
//

enum OADStatus: Int {
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
    func oadHandleEvent(peripheral: CBPeripheral, event: BLEManagerState, eventData: AnyObject!, error: NSError!)
    func oadDoUpdate(peripheral: CBPeripheral, fn: String, progress: M13ProgressViewPie) -> OADStatus
}