//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class DeviceNameDetail: TableDetail, UITextFieldDelegate {
    
    var nameField: UITextField!
    
    // MARK: - 💖 生命周期 (Lifecycle)
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Modal模式下键盘应该在界面之后出来。根据设置中iCloud改名返回时键盘在界面消失后消失无所谓
        nameField.becomeFirstResponder()
    }
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        title = LocalizedString("name")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancel")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "update:")
        nameField = UITextField()
        nameField.autocapitalizationType = .None
        nameField.autocorrectionType = .No
        nameField.clearButtonMode = .WhileEditing
        nameField.returnKeyType = .Done
        nameField.delegate = self
    }
    
    override func getItemView<T : CBPeripheral, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, cell: C) -> UITableViewCell {
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
        return false
    }
    
    // MARK: - 💛 Action
    func update(sender: AnyObject) {
    }
}
