//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DeviceDetail: TableDetail {
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        title = (data as CBPeripheral).name
        tableView.registerClass(RightDetailCell.self, forCellReuseIdentifier: cellId)
    }
    
    // MARK: - 💙 UITableViewDataSource    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 3
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as UITableViewCell
        cell.selectionStyle = .None
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = LocalizedString("name")
            cell.detailTextLabel?.text = (data as CBPeripheral).name
        case 1:
            if indexPath.row == 0 {
                cell.textLabel?.text = "UUID"
                cell.detailTextLabel?.text = (data as CBPeripheral).identifier.UUIDString
            }
        default: break
        }
        return cell
    }
}
