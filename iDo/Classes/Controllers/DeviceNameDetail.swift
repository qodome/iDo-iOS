//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class DeviceNameDetail: TableDetail, UITextFieldDelegate {
    
    var nameField: UITextField!
    
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
        nameField.becomeFirstResponder()
    }
    
    override func getItemView<T : CBPeripheral, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, cell: C) -> UITableViewCell {
        nameField.frame.origin.x = padding
        nameField.frame.size.width = cell.frame.width - padding * 2
        nameField.font = cell.textLabel?.font
        nameField.text = data?.name
        cell.addSubview(nameField)
        return cell
    }
    
    // MARK: -
    // MARK: 💙 UITableViewDelegate
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        nameField.frame.size.height = cell.frame.height
    }
    
    // MARK: - 💛 Action
    func update(sender: AnyObject) {
    }
}
