//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DeviceDetail: TableDetail {
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        items = [
            ["name"],
            ["version", "model", "serial_number", "UUID", "software", "manufacturer"]
        ]
        title = (data as CBPeripheral).name
    }
    
    override func getItemView<T : CBPeripheral, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, item: String, cell: C) -> UITableViewCell {
        switch item {
        case "name":
            cell.detailTextLabel?.text = data?.name
            cell.accessoryType = .DisclosureIndicator
            cell.selectionStyle = .Default
        case "update":
            cell.accessoryType = .DisclosureIndicator
            cell.selectionStyle = .Default
        case "version":
            cell.detailTextLabel?.text = data?.deviceInfo?.firmwareRevision
            let modelNumber = data?.deviceInfo?.modelNumber
            if modelNumber != nil && contains(PRODUCTS.keys, modelNumber!) {
                if items[0] == ["name"] {
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
        case "model":
            cell.detailTextLabel?.text = data?.deviceInfo?.modelNumber
        case "serial_number":
            cell.detailTextLabel?.text = data?.deviceInfo?.serialNumber.uppercaseString
        case "UUID":
            cell.detailTextLabel?.text = data?.identifier.UUIDString
        case "software":
            cell.detailTextLabel?.text = data?.deviceInfo?.softwareRevision
        case "manufacturer":
            cell.detailTextLabel?.text = data?.deviceInfo?.manufacturerName
        default: break
        }
        return cell
    }
    
    // MARK: 💙 UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = getItem(indexPath)
        if item == "name" {
            performSegueWithIdentifier("segue.device_detail-name", sender: self)
        } else if item == "update" {
            performSegueWithIdentifier("segue.device_detail-firmware_detail", sender: self)
        }
    }
    
    // MARK: - 💙 场景切换 (Segue)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        let dest = segue.destinationViewController as UIViewController
        if segue.identifier == "segue.device_detail-name" {
            (data as CBPeripheral).discoverServices([CBUUID(string: BLE_QODOME_SERVICE)])
            (dest as UINavigationController).childViewControllers[0].setValue(data, forKey: "data")
        } else if segue.identifier == "segue.device_detail-firmware_detail" {
            dest.setValue(data, forKey: "peripheral")
        }
    }
}
