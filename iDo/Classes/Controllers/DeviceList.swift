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
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffsetMake(0, -64), forBarMetrics: .Default)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refresh:")
        tableView.registerClass(SubtitleCell.self, forCellReuseIdentifier: cellId)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarStyle(.Default)
        BLEManager.sharedManager().delegate = self
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
        Log("设备列表界面状态更新: \(peripheral?.name) \(state.rawValue)")
        loadData()
    }
    
    // MARK: - 💛 Action
    func refresh(sender: AnyObject) {
        let header: UIView? = tableView.headerViewForSection(1)
        let indicator = UIActivityIndicatorView(frame: CGRectMake(view.frame.width - 35, 22, 20, 20))
        indicator.activityIndicatorViewStyle = .Gray
        header?.addSubview(indicator)
        indicator.hidden = false
        indicator.startAnimating()
        BLEManager.sharedManager().startScan() // 重新刷新界面时header会变成nil
    }
    
    // MARK: - 💙 UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? connected.count : data.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as UITableViewCell
        cell.imageView?.image = UIImage(named: "ic_settings_ido")
        cell.imageView?.layer.cornerRadius = 6
        cell.imageView?.layer.borderColor = UIColor.blackColor().CGColor
        cell.imageView?.layer.borderWidth = 0.5
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
            default: break
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
//            UIActionSheet(title: nil, delegate: self, cancelButtonTitle: LocalizedString("cancel"), destructiveButtonTitle: LocalizedString("disconnect")).showInView(view)
            UIActionSheet(title: nil, delegate: self, cancelButtonTitle: LocalizedString("cancel"), destructiveButtonTitle: LocalizedString("disconnect"), otherButtonTitles: LocalizedString("check")).showInView(view)
            tableView.deselectRowAtIndexPath(indexPath, animated: false) // 手动取消选中状态
        } else { // 直接绑定
            BLEManager.sharedManager().bind(data[indexPath.row] as CBPeripheral)
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 { // 已连接设备可点击进入详情页
            selected = connected[indexPath.row]
            performSegueWithIdentifier("segue.device_list-detail", sender: self)
        }
    }
    
    // MARK: 💙 UIActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == actionSheet.destructiveButtonIndex {
            BLEManager.sharedManager().unbind(selected!)
        } else if buttonIndex == 2 {
            performSegueWithIdentifier("segue.device_list-oad_detail", sender: self)
        }
    }
    
    // MARK: - 💙 场景切换 (Segue)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == "segue.device_list-detail" {
            segue.destinationViewController.setValue(selected, forKey: "data")
        } else if segue.identifier == "segue.device_list-oad_detail" {
            segue.destinationViewController.setValue(selected, forKey: "data")
            BLEManager.sharedManager().oadInit()
        }
    }
}
