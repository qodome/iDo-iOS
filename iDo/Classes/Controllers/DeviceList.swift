//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

class DeviceList: UITableViewController, DeviceChangeDelegate, UIAlertViewDelegate {
    
    let cellId = "device_list_cell"
    var data: [AnyObject] = []
    var devices: [AnyObject] = []
    
    var indicatorView: UIActivityIndicatorView!
    var selected: CBPeripheral!
    
    @IBOutlet weak var refreshBarBtn: UIBarButtonItem!
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedString("devices")
        refreshBarBtn.title = LocalizedString("refresh")
        // 还原导航栏
        navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.barStyle = UIBarStyle.Default
        navigationController?.navigationBar.tintColor = UIColor.colorWithHex(APP_COLOR)
        
        let deviceManager = BLEManager.sharedManager()
        deviceManager.changeDelegate = self
        devices = deviceManager.peripherals
        if deviceManager.connected != nil {
            data.append(deviceManager.connected!)
        }
    }
    
    // MARK: - onDataChange
    func onDataChange(unconnected: [CBPeripheral], connected: CBPeripheral?) {
        if connected != nil {
            data.append(connected!)
        }
        devices = unconnected
        tableView.reloadData()
    }
    
    // MARK: - 💙 场景切换 (Segue)
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "peripheralDetailInforimation" {
            let controller = segue.destinationViewController as DeviceDetail
            controller.data = selected
        }
    }
    
    // MARK: - 💙 UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? data.count : devices.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: DeviceCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as DeviceCell
        var device: CBPeripheral
        cell.indicator.hidden = true
        if indexPath.section == 0 {
            device = data[indexPath.row] as CBPeripheral
            if BLEManager.sharedManager().isPeripheralTryToConnect {
                cell.indicator.hidden = false
                cell.indicator.startAnimating()
                cell.icon.hidden = true
            } else {
                cell.indicator.hidden = true
                cell.icon.hidden = false
            }
        } else {
            device = devices[indexPath.row] as CBPeripheral
            cell.icon.hidden = false
        }
        cell.title.text = device.name
        cell.subtitle.text = device.identifier.UUIDString
        return cell
    }
    
    // MARK: 💙 UITableViewDelegate
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return 20.0
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView {
        var tableHeaderView: UIView = UIView(frame: CGRectMake(CGPointZero.x, CGPointZero.y, 320.0, 20.0))
        tableHeaderView.backgroundColor = UIColor.whiteColor()
        var deviceStatusLabel: UILabel = UILabel(frame: CGRectMake(CGPointZero.x + 10, CGPointZero.y, tableHeaderView.frame.size.width - 10, tableHeaderView.frame.size.height))
        deviceStatusLabel.font = UIFont.systemFontOfSize(12)
        tableHeaderView.addSubview(deviceStatusLabel)
        if section == 0 {
            deviceStatusLabel.text = LocalizedString("Connected devices")
        } else {
            deviceStatusLabel.text = LocalizedString("Available devices")
            indicatorView = UIActivityIndicatorView(frame: CGRectMake(90, CGPointZero.y, 20, 20))
            indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
            tableHeaderView.addSubview(indicatorView)
        }
        return tableHeaderView
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            selected = data[indexPath.row] as CBPeripheral
            var title = LocalizedString("warning")
            var message = LocalizedString("Jump to devices detail page or disConnect this device?")
            var cancelBtnTittle = LocalizedString("Back")
            var otherBtnTitle1 = LocalizedString("DisConnect")
            var otherBtnTitle2 = LocalizedString("details")
            UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelBtnTittle, otherButtonTitles: otherBtnTitle1, otherBtnTitle2).show()
        } else {
            BLEManager.sharedManager().connect(indexPath.row)
        }
    }
    
    // MARK: 💙 UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            BLEManager.sharedManager().unbind(selected)
        } else if buttonIndex == 2 {
            println("设备详情")
            performSegueWithIdentifier("peripheralDetailInforimation", sender: self)
        }
    }
    
    // MARK: - Action
    @IBAction func refreshPeripherals(sender: AnyObject) {
        BLEManager.sharedManager().startScan()
        indicatorView.startAnimating()
        indicatorView.hidden = false
    }
}
