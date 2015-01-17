//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DeviceDetail: TableDetail {
    
    let menu = ["version", "model", "UUID", "bluetooth", "software", "manufacturer"]
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        title = (data as CBPeripheral).name
        tableView.registerClass(RightDetailCell.self, forCellReuseIdentifier: cellId)
    }
    
    override func getItemView<T : CBPeripheral, C : RightDetailCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, cell: C) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = LocalizedString("name")
            cell.detailTextLabel?.text = data?.name
            cell.accessoryType = .DisclosureIndicator
        case 1:
            cell.selectionStyle = .None
            cell.textLabel?.text = LocalizedString(menu[indexPath.row])
            switch indexPath.row {
            case 0:
                cell.detailTextLabel?.text = data?.deviceInfo?.firmwareRevision
            case 1:
                cell.detailTextLabel?.text = data?.deviceInfo?.modelNumber
            case 2:
                cell.detailTextLabel?.text = data?.identifier.UUIDString
            case 3:
                cell.detailTextLabel?.text = data?.deviceInfo?.serialNumber
            case 4:
                cell.detailTextLabel?.text = data?.deviceInfo?.softwareRevision
            case 5:
                cell.detailTextLabel?.text = data?.deviceInfo?.manufacturerName
            default: break
            }
        default: break
        }
        return cell
    }
    
    // MARK: - 💙 UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : menu.count
    }
}
