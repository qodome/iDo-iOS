//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

class DeviceList: UITableViewController, DeviceCentralManagerdidChangedCurrentConnectedDeviceDelegate, DeviceCentralManagerDidStartsendDataDelegate, UIAlertViewDelegate {

    let IDOLOGREDCOLOR = Util.ColorFromRGB(0xFB414D)
    let cellId = "device_list_cell"

    var data: [AnyObject] = []
    var devices: [AnyObject] = []
    var mDeviceCentralManger: DeviceCentralManager!

    var indicatorView: UIActivityIndicatorView!
    var currentIndexPathRow: Int = -1 //不好

    @IBOutlet weak var refreshBarBtn: UIBarButtonItem!

    // MARK: - 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Util.LocalizedString("devices")
        refreshBarBtn.title = Util.LocalizedString("refresh")
        recoverTranslucentedNavigationBar()

        mDeviceCentralManger = DeviceCentralManager.instanceForCenterManager()
        mDeviceCentralManger.delegate = self
        mDeviceCentralManger.startSendingDataDelegate = self
        devices = mDeviceCentralManger.devices
        data = mDeviceCentralManger.devicesArrayOnSelectedStatus
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        mDeviceCentralManger.disConnectOtherPeripheralAfterBandedAConnectingPeripheral()
        if mDeviceCentralManger.isShowAllCanConnectedDevices {
            mDeviceCentralManger.stopScanPeripherals() // TODO: 有问题
            mDeviceCentralManger.isShowAllCanConnectedDevices = false
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "peripheralDetailInforimation" {
            var detailInforVC = segue.destinationViewController as DeviceDetail
            detailInforVC.data = data[currentIndexPathRow] as CBPeripheral
        }
    }

    // MARK: - UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return data.count
        }
        return devices.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: DeviceCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as DeviceCell
        var device: CBPeripheral
        cell.indicator.hidden = true
        if indexPath.section == 0 {
            device = data[indexPath.row] as CBPeripheral
            if mDeviceCentralManger.isPeripheralTryToConnect {
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

    // MARK: - UITableViewDelegate
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
            deviceStatusLabel.text =  Util.LocalizedString("Connected devices")
        } else {
            deviceStatusLabel.text = Util.LocalizedString("Available devices")
            indicatorView = UIActivityIndicatorView(frame: CGRectMake(90, CGPointZero.y, 20, 20))
            indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
            tableHeaderView.addSubview(indicatorView)
            if mDeviceCentralManger.isShowAllCanConnectedDevices {
                indicatorView.startAnimating()
                indicatorView.hidden = false
            } else {
                indicatorView.stopAnimating()
                indicatorView.hidden = true
            }
        }
        return tableHeaderView
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            currentIndexPathRow = indexPath.row
            var title = Util.LocalizedString("warning")
            var message = Util.LocalizedString("Jump to devices detail page or disConnect this device?")
            var cancelBtnTittle = Util.LocalizedString("Back")
            var otherBtnTitle1 = Util.LocalizedString("DisConnect")
            var otherBtnTitle2 = Util.LocalizedString("details")
            UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelBtnTittle, otherButtonTitles: otherBtnTitle1, otherBtnTitle2).show()
        } else {
            mDeviceCentralManger.userConnectPeripheral(indexPath.row)
        }
    }

    // MARK: - didChangedCurrentConnectedDevice Delegate
    func centralss(centeral: CBCentralManager, unConnectedDevices unConnectedDeviceArr: NSArray, connectedDevices connectedDeviceArr: NSArray) {
        data = NSMutableArray(array: connectedDeviceArr)
        devices = NSMutableArray(array: unConnectedDeviceArr)
        tableView.reloadData()
    }

    // MARK: -  DeviceCentralManager DidStartsendData Delegate
    func deviceCentralManagerDidStartsendData() {
        //停止loading
        tableView.reloadData()
    }

    // MARK: - uiAlertView Delegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            mDeviceCentralManger.unbind(data[currentIndexPathRow] as CBPeripheral)
        } else if buttonIndex == 2 {
            println("设备详情")
            performSegueWithIdentifier("peripheralDetailInforimation", sender: self)
        }
    }

    // MARK: - Action
    @IBAction func refreshPeripherals(sender: AnyObject) {
        mDeviceCentralManger.isShowAllCanConnectedDevices = true
        mDeviceCentralManger.startScanPeripherals()
        indicatorView.startAnimating()
        indicatorView.hidden = false
    }

    // MARK: - Custom Method
    func recoverTranslucentedNavigationBar(){
        navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.barStyle = UIBarStyle.Default
        navigationController?.navigationBar.tintColor = IDOLOGREDCOLOR
    }

}
