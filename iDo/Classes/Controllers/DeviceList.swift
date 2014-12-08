//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DeviceList: UITableViewController, BLEManagerDelegate, UIActionSheetDelegate {
    
    var data = []
    var cellId = "list_cell"
    var connected: [CBPeripheral] = []
    var selected: CBPeripheral?
    var state: BLEManagerState!
    
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
        data = BLEManager.sharedManager().peripherals
        connected = BLEManager.sharedManager().central.retrieveConnectedPeripheralsWithServices([CBUUID(string: kServiceUUID)]) as [CBPeripheral]
    }
    
    // MARK: - 🐤 BLEManagerDelegate
    func onStateChanged(state: BLEManagerState, peripheral: CBPeripheral?) {
        self.state = state
        Log("状态更新: \(peripheral?.name) \(state.rawValue)")
        data = BLEManager.sharedManager().peripherals
        connected = BLEManager.sharedManager().central.retrieveConnectedPeripheralsWithServices([CBUUID(string: kServiceUUID)]) as [CBPeripheral]
        Log("连接数: \(connected.count)")
        tableView.reloadData()
    }
    
    // MARK: - 💛 Action
    func refresh(sender: AnyObject) {
        BLEManager.sharedManager().startScan()
        var header: UIView = tableView.headerViewForSection(1)!
        var indicator = UIActivityIndicatorView(frame: CGRectMake(64, 22, 20, 20))
        indicator.activityIndicatorViewStyle = .Gray
        header.addSubview(indicator)
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
        //        cell.indicator.hidden = true
        if indexPath.section == 0 {
            device = connected[indexPath.row]
            cell.accessoryType = .DetailButton
            if state == BLEManagerState.Connecting {
                //                cell.indicator.hidden = false
                //                cell.indicator.startAnimating()
                cell.imageView?.hidden = true
            } else {
                //                cell.indicator.hidden = true
                cell.imageView?.hidden = false
            }
        } else {
            device = data[indexPath.row] as CBPeripheral
            cell.accessoryType = .None            
            cell.imageView?.hidden = false
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
            BLEManager.sharedManager().bind(indexPath.row)
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
