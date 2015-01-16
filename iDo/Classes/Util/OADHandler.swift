//
//  Copyright (c) 2015年 NY. All rights reserved.
//

enum OADStatus: Int {
    case OADAvailable
    case OADNotAvailable
    case OADNotSupported
    case OADAlreadyLatest
    case OADReady
    case OADProgressUpdate
    case OADConfirmResult
    case OADSuccess
    case OADFailed
}

protocol OADHandlerDelegate {
    func oadStatusUpdate(status: OADStatus, info: String?, progress: UInt8, peripheral: CBPeripheral?)
}

protocol OADHandler {
    var delegate: OADHandlerDelegate? { get set }
    
    func oadPrepare(peripheral: CBPeripheral)
    func oadHandleEvent(peripheral: CBPeripheral, event: BLEManagerState, eventData: AnyObject!, error: NSError!)
    func oadDoUpdate(peripheral: CBPeripheral)
}


