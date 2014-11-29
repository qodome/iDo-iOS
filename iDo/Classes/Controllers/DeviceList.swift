//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DeviceList: UITableViewController, BLEManagerDelegate, UIAlertViewDelegate {
    
    var data = []
    var cellId = "list_cell"
    
    var connected = []
    var selected: CBPeripheral?
    
    var state: BLEManagerState!
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(SubtitleCell.self, forCellReuseIdentifier: cellId)
        title = LocalizedString("devices")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refresh:")
        
        let deviceManager = BLEManager.sharedManager()
        deviceManager.delegate = self
        data = deviceManager.peripherals
        connected = BLEManager.sharedManager().central.retrieveConnectedPeripheralsWithServices([CBUUID(string: kServiceUUID)])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarStyle(.Default)
    }
    
    // MARK: - 🐤 BLEManagerDelegate
    func onStateChanged(state: BLEManagerState, peripheral: CBPeripheral?) {
        self.state = state
        Log("状态更新: \(peripheral?.name) \(state.rawValue)")
        data = BLEManager.sharedManager().peripherals
        connected = BLEManager.sharedManager().central.retrieveConnectedPeripheralsWithServices([CBUUID(string: kServiceUUID)])
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
        cell.imageView.image = UIImage(named: "iDoIcon")
        var device: CBPeripheral
        //        cell.indicator.hidden = true
        if indexPath.section == 0 {
            device = connected[indexPath.row] as CBPeripheral
            if state == BLEManagerState.Connecting {
                //                cell.indicator.hidden = false
                //                cell.indicator.startAnimating()
                cell.imageView.hidden = true
            } else {
                //                cell.indicator.hidden = true
                cell.imageView.hidden = false
            }
        } else {
            device = data[indexPath.row] as CBPeripheral
            cell.imageView.hidden = false
        }
        cell.textLabel.text = device.name
        cell.detailTextLabel?.text = device.identifier.UUIDString
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? LocalizedString("devices") : nil
    }
    
    // MARK: 💙 UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            selected = connected[indexPath.row] as? CBPeripheral
            var title = LocalizedString("warning")
            var message = LocalizedString("Jump to devices detail page or disConnect this device?")
            var cancelBtnTittle = LocalizedString("Back")
            var otherBtnTitle1 = LocalizedString("DisConnect")
            var otherBtnTitle2 = LocalizedString("details")
            UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelBtnTittle, otherButtonTitles: otherBtnTitle1, otherBtnTitle2).show()
        } else {
            BLEManager.sharedManager().bind(indexPath.row)
        }
    }
    
    // MARK: 💙 UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            BLEManager.sharedManager().unbind(selected!)
        } else if buttonIndex == 2 {
            performSegueWithIdentifier("segue_device_list_detail", sender: self)
        }
    }
    
    // MARK: - 💙 场景切换 (Segue)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        segue.destinationViewController.setValue(selected, forKey: "data")
    }
}
