//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class DeviceList: TableList, BLEManagerDelegate, UIActionSheetDelegate {
    
    var connected: [CBPeripheral] = []
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        BLEManager.sharedManager.delegate = self
        loadData()
    }
    
    func loadData() {
        listData.removeAll(keepCapacity: true)
        connected.removeAll(keepCapacity: true)
        for peripheral in BLEManager.sharedManager.peripherals {
            if peripheral.state == .Connected {
                connected.append(peripheral)
            } else {
                listData.append(peripheral)
            }
        }
        (listView as UITableView).reloadData()
    }
    
    // MARK: - 🐤 继承 Taylor
    override func setTableViewStyle() -> UITableViewStyle {
        return .Grouped
    }
    
    override func onPrepare() {
        super.onPrepare()
        title = LocalizedString("devices")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "ic_action_close"), style: .Bordered, target: self, action: "cancel")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "refresh:")
        (listView as UITableView).registerClass(SubtitleCell.self, forCellReuseIdentifier: cellId)
        refreshControl.removeFromSuperview()
    }
    
    // MARK: - 🐤 BLEManagerDelegate
    func onChanged(peripheral: CBPeripheral?, event: BLEManagerEvent) {
        Log("-- 设备列表界面状态更新: \(peripheral?.name) \(event.rawValue)")
        loadData()
    }
    
    // MARK: - 💛 Action
    func refresh(sender: AnyObject) {
        let header: UIView? = (listView as UITableView).headerViewForSection(1)
        let indicator = UIActivityIndicatorView(frame: CGRectMake(view.frame.width - 35, 22, 20, 20))
        indicator.activityIndicatorViewStyle = .Gray
        header?.addSubview(indicator)
        indicator.hidden = false
        indicator.startAnimating()
        BLEManager.sharedManager.startScan() // 重新刷新界面时header会变成nil
    }
    
    // MARK: - 💙 UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? connected.count : getCount()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell { // section为2所以不继承getItemView直接重写tableView
        let cell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as UITableViewCell
        var item: CBPeripheral
        if indexPath.section == 0 {
            item = connected[indexPath.row]
            cell.textLabel?.text = item.name
            cell.imageView?.hidden = false
            cell.accessoryType = .DetailButton
        } else {
            item = getItem(indexPath.row) as CBPeripheral
            cell.textLabel?.text = item.name
            switch item.state {
            case .Connecting:
                cell.imageView?.hidden = true
                let indicator = UIActivityIndicatorView(frame: CGRectMake(19.5, cell.frame.height / 2 - 10, 20, 20))
                indicator.activityIndicatorViewStyle = .Gray
                indicator.startAnimating()
                cell.addSubview(indicator)
            case .Disconnected:
                cell.imageView?.hidden = false
            default: break
            }
            cell.accessoryType = .None
        }
        let modelNumber = item.deviceInfo?.modelNumber
        if modelNumber != nil && contains(PRODUCTS.keys, modelNumber!) {
            cell.imageView?.image = UIImage(named: "ic_settings_ido")
        } else {
            cell.imageView?.image = UIImage.imageWithColor(UIColor.whiteColor(), size: CGSizeSettingsIcon)
        }
        cell.imageView?.image = UIImage(named: "ic_settings_ido")
        cell.imageView?.layer.cornerRadius = 6
        cell.imageView?.layer.borderColor = UIColor.blackColor().CGColor
        cell.imageView?.layer.borderWidth = 0.5
        cell.detailTextLabel?.text = item.identifier.UUIDString
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? nil : LocalizedString("devices")
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 0 // 已绑定设备可滑动解绑
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            BLEManager.sharedManager.unbind(connected[indexPath.row])
        }
    }
    
    // MARK: 💙 UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 { // 进入详情页
            selected = connected[indexPath.row]
            performSegueWithIdentifier("segue.device_list-detail", sender: self)
        } else {
            let item = getItem(indexPath.row) as CBPeripheral
            if BLEManager.sharedManager.defaultDevice() != nil {
                UIActionSheet(title: LocalizedString("bind") + " \(item.name)?", delegate: self, cancelButtonTitle: LocalizedString("cancel"), destructiveButtonTitle: LocalizedString("ok")).showInView(view)
            } else { // 直接绑定
                BLEManager.sharedManager.bind(getItem(indexPath.row) as CBPeripheral)
            }
        }
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 { // 已连接设备可点击进入详情页
            selected = connected[indexPath.row]
            performSegueWithIdentifier("segue.device_list-detail", sender: self)
        }
    }
    
    // MARK: 💙 UIActionSheetDelegate
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        let indexPath = (listView as UITableView).indexPathForSelectedRow()
        if indexPath != nil {
            if buttonIndex == actionSheet.destructiveButtonIndex {
                BLEManager.sharedManager.bind(getItem(indexPath!.row) as CBPeripheral)
            } else {
                (listView as UITableView).deselectRowAtIndexPath(indexPath!, animated: true)
            }
        }
    }
    
    // MARK: - 💙 场景切换 (Segue)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        segue.destinationViewController.setValue(selected, forKey: "data")
    }
}
