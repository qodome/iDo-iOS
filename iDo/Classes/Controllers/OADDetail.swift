//
//  Copyright (c) 2015年 NY. All rights reserved.
//

enum OADDetailState: Int {
    case Init
    case ReadyForUpdate
    case InProgress
    case Done
}

class OADDetail: UIViewController, BLEManagerOADSource {

    var data: CBPeripheral?
    var state: OADDetailState?
    var lastProgress: UInt8?
    var textInfo: UITextField!
    var actionButton: UIButton!
    var progressBar: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BLEManager.sharedManager().oadSource = self
        title = data?.name
        state = .Init
        lastProgress = 0
        
        textInfo = UITextField(frame: CGRectMake(padding, 80, view.frame.width - padding * 2, 44))
        textInfo.text = LocalizedString("update")
        view.addSubview(textInfo)
        actionButton = UIButton(frame: CGRectMake(padding, 130, view.frame.width - padding * 2, 44))
        actionButton.setTitle(LocalizedString("button"), forState: .Normal)
        actionButton.backgroundColor = UIColor.blueColor()
        actionButton.addTarget(self, action: "checkUpdateBtnAction:", forControlEvents: .TouchUpInside)
        view.addSubview(actionButton)
        progressBar = UIProgressView(frame: CGRectMake(padding, 180, view.frame.width - padding * 2, 4))
        view.addSubview(progressBar)
    }
    
    func checkUpdateBtnAction(sender: AnyObject) {
        Log("button")
        
        if state == .Init {
            println("Check image version")
            BLEManager.sharedManager().oadPrepare(data!)
        } else if state == .ReadyForUpdate {
            BLEManager.sharedManager().oadDoUpdate(data!)
            actionButton.setTitle("Update In Progress", forState: UIControlState.Normal)
            actionButton.enabled = false
            state = .InProgress
        } else if state == .Done {
            // NULL action
        }
    }
    
    func onUpdateOADInfo(status: OADStatus, info: String?, progress: UInt8) {
        if status == OADStatus.OADNotSupported {
            textInfo.text = LocalizedString("Device is not supported")
            actionButton.setTitle(LocalizedString("DevNotSupported"), forState: UIControlState.Normal)
            actionButton.enabled = false
            state = .Done
        } else if status == OADStatus.OADAlreadyLatest {
            textInfo.text = LocalizedString("Firmware version already latest")
            actionButton.setTitle(LocalizedString("AlreadyLatest"), forState: UIControlState.Normal)
            actionButton.enabled = false
            state = .Done
        } else if status == OADStatus.OADReady {
            textInfo.text = LocalizedString("OAD is ready to start")
            actionButton.setTitle(LocalizedString("DoUpdate"), forState: UIControlState.Normal)
            actionButton.enabled = true
            state = .ReadyForUpdate
        } else if status == OADStatus.OADProgressUpdate {
            if progress > lastProgress {
                progressBar.progress = Float(progress) / 100.0
                lastProgress = progress
            }
            textInfo.text = LocalizedString("Update in progress: " + String(progress) + "%")
        } else if status == OADStatus.OADNotAvailable {
            textInfo.text = LocalizedString("OAD service not available, check network connection?")
            actionButton.setTitle(LocalizedString("ServiceNA"), forState: UIControlState.Normal)
            actionButton.enabled = false
            state = .Done
        } else if status == OADStatus.OADSuccess {
            textInfo.text = LocalizedString("OAD success, your new firmware is running!")
            actionButton.setTitle(LocalizedString("OK"), forState: UIControlState.Normal)
            actionButton.enabled = false
            state = .Done
        } else if status == OADStatus.OADFailed {
            textInfo.text = LocalizedString("OAD failed, please retry or contact service")
            actionButton.setTitle(LocalizedString("Failed"), forState: UIControlState.Normal)
            actionButton.enabled = false
            state = .Done
        }
    }
}
