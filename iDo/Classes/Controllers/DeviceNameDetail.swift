//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class DeviceNameDetail: TableDetail, UITextFieldDelegate, BLEManagerDelegate {
    
    var nameField: UITextField!
    
    var HUD: M13ProgressHUD!
    
    // MARK: - 💖 生命周期 (Lifecycle)
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
        HUD = M13ProgressHUD(progressView: M13ProgressViewRing())
        HUD.progressViewSize = CGSizeMake(60, 60)
        HUD.animationPoint = CGPointMake(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        HUD.hudBackgroundColor = UIColor.whiteColor()
        HUD.statusColor = UIColor.defaultColor()
        HUD.maskType = M13ProgressHUDMaskTypeSolidColor // MaskTypeIOS7Blur参数无效
        UIApplication.sharedApplication().delegate?.window!!.addSubview(HUD)
        BLEManager.sharedManager.delegate = self
    }
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        items = [[""]] // 占位
        title = LocalizedString("name")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "update:")
        nameField = UITextField()
        nameField.autocapitalizationType = .None
        nameField.autocorrectionType = .No
        nameField.clearButtonMode = .WhileEditing
        nameField.returnKeyType = .Done
        nameField.delegate = self
    }
    
    override func getItemView<T : CBPeripheral, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, item: String, cell: C) -> UITableViewCell {
        nameField.text = data?.name
        cell.addSubview(nameField)
        return cell
    }
    
    // MARK: -
    // MARK: 💙 UITableViewDelegate
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        setField(nameField, cell: cell)
    }
    
    // MARK: 💙 UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        update(self)
        return false
    }
    
    // MARK: - 💛 Action
    func update(sender: AnyObject) {
        nameField.resignFirstResponder()
        BLEManager.sharedManager.peripheralName = nameField.text.stringByTrimmingCharactersInSet(NSCharacterSet
            .whitespaceCharacterSet())
        if BLEManager.sharedManager.peripheralName != (data as CBPeripheral).name {
            HUD.progressView.indeterminate = true
            HUD.show(true)
            (data as CBPeripheral).discoverServices([CBUUID(string: BLE_QODOME_SERVICE)])
        }
    }
    
    // MARK: - 🐤 BLEManagerDelegate
    func onChanged(peripheral: CBPeripheral?, event: BLEManagerEvent) {
        if event == .Renamed {
            HUD.performAction(M13ProgressViewActionSuccess, animated: true)
            HUD.progressView.indeterminate = false
            delay(1 + Double(self.HUD.animationDuration)) {
                self.HUD.hide(true)
                self.HUD.performAction(M13ProgressViewActionNone, animated: false)
                self.cancel()
            }
        }
    }
    
    // MARK: - 💙 场景切换 (Segue)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        println(segue.identifier)
    }
}
