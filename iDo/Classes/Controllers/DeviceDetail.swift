//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DeviceDetail: UITableViewController {
    
    var data: CBPeripheral?
    var cellId = "list_cell"
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(RightDetailCell.self, forCellReuseIdentifier: cellId)
        title = data?.name
    }
    
    // MARK: - 💙 UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as UITableViewCell
        cell.selectionStyle = .None
        switch indexPath.section {
        case 0:
            cell.textLabel.text = LocalizedString("name")
            cell.detailTextLabel?.text = data?.name
        case 1:
            cell.textLabel.text = "UUID"
            cell.detailTextLabel?.text = data?.identifier.UUIDString
        default:
            println("error") // TODO: 统一处理
        }
        return cell
    }
}
