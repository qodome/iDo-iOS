//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DeviceList: UITableViewController, BLEManagerDelegate, UIActionSheetDelegate {
    
    var data: [AnyObject] = []
    var cellId = "list_cell"
    var connected: [CBPeripheral] = []
    var selected: CBPeripheral?
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedString("devices")
        tableView.registerClass(SubtitleCell.self, forCellReuseIdentifier: cellId)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refresh:")
        BLEManager.sharedManager().delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarStyle(.Default)
        loadData()
    }
    
    func loadData() {
        data.removeAll(keepCapacity: true)
        connected.removeAll(keepCapacity: true)
        for peripheral in BLEManager.sharedManager().peripherals {
            if peripheral.state == .Connected {
                connected.append(peripheral)
            } else {
                data.append(peripheral)
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - 🐤 BLEManagerDelegate
    func onStateChanged(state: BLEManagerState, peripheral: CBPeripheral?) {
        Log("状态更新: \(peripheral?.name) \(state.rawValue)")
        loadData()
    }
    
    // MARK: - 💛 Action
    func refresh(sender: AnyObject) {
        BLEManager.sharedManager().startScan()
        let header: UIView = tableView.headerViewForSection(1)!
        let indicator = UIActivityIndicatorView(frame: CGRectMake(view.frame.width - 35, 22, 20, 20))
        indicator.activityIndicatorViewStyle = .Gray
        header.addSubview(indicator)
        indicator.hidden = false
        indicator.startAnimating()
    }
    
    // MARK: - 💙 UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? connected.count : data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as UITableViewCell
        cell.imageView?.image = UIImage(named: "ic_settings_ido")
        UIImageView.roundedView(cell.imageView, cornerRadius: 6, borderColor: UIColor.blackColor(), borderWidth: 0.5)
        var device: CBPeripheral
        if indexPath.section == 0 {
            device = connected[indexPath.row]
            cell.imageView?.hidden = false
            cell.accessoryType = .DetailButton
        } else {
            device = data[indexPath.row] as CBPeripheral
            switch device.state {
            case .Connecting:
                cell.imageView?.hidden = true
                let indicator = UIActivityIndicatorView(frame: CGRectMake(20.5, cell.frame.height / 2 - 10, 20, 20))
                indicator.activityIndicatorViewStyle = .Gray
                indicator.startAnimating()
                cell.addSubview(indicator)
            case .Disconnected:
                cell.imageView?.hidden = false
            default:
                println("**********************************************************")
            }
            cell.accessoryType = .None
        }
        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = device.identifier.UUIDString
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? nil : LocalizedString("devices")
    }
    
    // MARK: 💙 UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 { // 询问是否断开
            selected = connected[indexPath.row]
            UIActionSheet(title: nil, delegate: self, cancelButtonTitle: LocalizedString("cancel"), destructiveButtonTitle: LocalizedString("disconnect")).showInView(view)
        } else { // 直接绑定
            BLEManager.sharedManager().bind(data[indexPath.row] as CBPeripheral)
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 { // 已连接设备可点击进入详情页
            selected = connected[indexPath.row]
            performSegueWithIdentifier("segue_device_list_detail", sender: self)
        }
    }
    
    // MARK: 💙 UIActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == actionSheet.destructiveButtonIndex {
            BLEManager.sharedManager().unbind(selected!)
        }
    }
    
    // MARK: - 💙 场景切换 (Segue)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        segue.destinationViewController.setValue(selected, forKey: "data")
    }
}
