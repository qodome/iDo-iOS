//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

class DeviceDetail: UITableViewController {
    
    let cellId = "device_detail_cell"
    var data: CBPeripheral!
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = data.name
    }
    
    // MARK: - 💙 UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as UITableViewCell
        cell.selectionStyle = UITableViewCellSelectionStyle.None // 为了灵活不要放到storyboard设置
        switch indexPath.section {
        case 0:
            cell.textLabel.text = LocalizedString("name")
            cell.detailTextLabel?.text = data.name
        case 1:
            cell.textLabel.text = LocalizedString("bluetooth")
            cell.detailTextLabel?.text = data.identifier.UUIDString
        default:
            println("error") // TODO: 统一处理
        }
        return cell
    }
}
