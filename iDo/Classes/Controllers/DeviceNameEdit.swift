//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class DeviceNameEdit: BaseFieldEdit, BLEManagerDelegate {
    
    var HUD: M13ProgressHUD!
    
    // MARK: - 💖 生命周期 (Lifecycle)
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
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
        title = LocalizedString("name")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "update")
    }
    
    override func getItemView<T : CBPeripheral, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, item: String, cell: C) -> UITableViewCell {
        textField.text = data?.name
        cell.addSubview(textField)
        return cell
    }
    
    override func update() {
        super.update()
        BLEManager.sharedManager.peripheralName = textField.text.stringByTrimmingCharactersInSet(NSCharacterSet
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
            delay(1 + Double(self.HUD.animationDuration)) {
                self.HUD.performAction(M13ProgressViewActionSuccess, animated: true)
                self.HUD.progressView.indeterminate = false
                delay(1 + Double(self.HUD.animationDuration)) {
                    self.HUD.hide(true)
                    self.HUD.performAction(M13ProgressViewActionNone, animated: false)
                    self.cancel()
                }
            }
        }
    }
}
