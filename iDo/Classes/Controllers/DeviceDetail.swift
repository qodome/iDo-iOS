//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DeviceDetail: TableDetail {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = BLEManager.sharedManager.peripheralName
    }
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        items = [
            ["name"],
            ["version", "model", "serial_number", "UUID", "manufacturer"]
        ]
    }
    
    override func getItemView<T : CBPeripheral, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, item: String, cell: C) -> UITableViewCell {
        switch item {
        case "name":
            cell.detailTextLabel?.text = BLEManager.sharedManager.peripheralName
            let firmwareRevision = data?.deviceInfo?.firmwareRevision
            let modelNumber = data?.deviceInfo?.modelNumber
            if  modelNumber != nil && contains(PRODUCTS.keys, modelNumber!) { // 如果是我们的设备
                cell.accessoryType = .DisclosureIndicator
                cell.selectionStyle = .Default
                if firmwareRevision != nil && items[0] == ["name"] {
                    items[0] += ["update"] // Check for Update
                    tableView.reloadData()
                }
                //                let button = UIButton()
                //                let color = UIColor.defaultColor()
                //                button.setTitle(LocalizedString("update"), forState: .Normal)
                //                button.setTitleColor(color, forState: .Normal)
                //                button.setTitleColor(UIColor.whiteColor(), forState: .Highlighted)
                //                //                    button.backgroundColor = color
                //                button.titleLabel?.font = UIFont(name: "HelveticaNeue-Bold", size: 13)
                //                button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10)
                //                button.sizeToFit()
                //                button.layer.cornerRadius = 4
                //                button.layer.borderColor = color.CGColor
                //                button.layer.borderWidth = 1
                //                button.frame.size.height = 26 // AppStore更新按钮和进度圈都是26高
                //                cell.accessoryView = button
            }
        case "update":
            cell.accessoryType = .DisclosureIndicator
            cell.selectionStyle = .Default
        case "version":
            cell.detailTextLabel?.text = data?.deviceInfo?.firmwareRevision
        case "model":
            cell.detailTextLabel?.text = data?.deviceInfo?.modelNumber
        case "serial_number":
            cell.detailTextLabel?.text = data?.deviceInfo?.serialNumber?.uppercaseString
        case "UUID":
            cell.detailTextLabel?.text = data?.identifier.UUIDString
        case "manufacturer":
            let modelNumber = data?.deviceInfo?.modelNumber
            if  modelNumber != nil && contains(PRODUCTS.keys, modelNumber!) {
                cell.detailTextLabel?.text = LocalizedString("qodome_co_ltd")
            }
            if data?.deviceInfo?.manufacturerName != nil {
                cell.detailTextLabel?.text = data?.deviceInfo?.manufacturerName
            }
        default: break
        }
        return cell
    }
    
    // MARK: 💙 UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if tableView.cellForRowAtIndexPath(indexPath)!.accessoryType == .DisclosureIndicator {
            let item = getItem(indexPath)
            if item == "name" {
                performSegueWithIdentifier("segue.device_detail-name", sender: self)
            } else if item == "update" {
                performSegueWithIdentifier("segue.device_detail-firmware_detail", sender: self)
            }
        }
    }
    
    // MARK: - 💙 场景切换 (Segue)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        let dest = segue.destinationViewController as UIViewController
        if segue.identifier == "segue.device_detail-name" {
            dest.setValue(data, forKey: "data")
        } else if segue.identifier == "segue.device_detail-firmware_detail" {
            dest.setValue(data, forKey: "peripheral")
        }
    }
}
