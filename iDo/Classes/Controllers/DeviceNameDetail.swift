//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class DeviceNameDetail: TableDetail, UITextFieldDelegate {
    
    var nameField: UITextField!
    
    // MARK: - 💖 生命周期 (Lifecycle)
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
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
        nameField.text = BLEManager.sharedManager.peripheralName
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
            (data as CBPeripheral).discoverServices([CBUUID(string: BLE_QODOME_SERVICE)])
        }
        cancel()
    }
}
