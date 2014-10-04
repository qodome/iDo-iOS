//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

class DeviceList: UITableViewController, DeviceCentralManagerdidChangedCurrentConnectedDeviceDelegate, DeviceCentralManagerDidStartsendDataDelegate, DeviceCentralManagerBuleToothDoNotOpenDelegate, UIAlertViewDelegate {

    let IDOLOGREDCOLOR = Util.ColorFromRGB(0xFB414D)
    let cellId = "deviceCell"

    var devicesArrayOnSelectedStatus: NSMutableArray?
    var devicesArrayOnNoSelectedStatus: NSMutableArray?
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
        mDeviceCentralManger.blueToothDoNotOPenDelegate = self
        mDeviceCentralManger.delegate = self
        mDeviceCentralManger.startSendingDataDelegate = self
        devicesArrayOnNoSelectedStatus = mDeviceCentralManger.devicesArrayOnNoSelectedStatus
        devicesArrayOnSelectedStatus = mDeviceCentralManger.devicesArrayOnSelectedStatus
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
            detailInforVC.peripheral = devicesArrayOnSelectedStatus![currentIndexPathRow] as CBPeripheral
        }
    }

    // MARK: - UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return devicesArrayOnSelectedStatus!.count
        }
        return devicesArrayOnNoSelectedStatus!.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:PeripheralSelectedTableViewCell = tableView.dequeueReusableCellWithIdentifier(cellId, forIndexPath: indexPath) as PeripheralSelectedTableViewCell
        var peripheralDevice:CBPeripheral!
        cell.sActivityIndictor?.hidden = true
        if 0 == indexPath.section {
            peripheralDevice = devicesArrayOnSelectedStatus![indexPath.row] as CBPeripheral
            if mDeviceCentralManger.isPeripheralTryToConnect{
                cell.sActivityIndictor?.hidden = false
                cell.sActivityIndictor?.startAnimating()
                cell.sImageView?.hidden = true
            }
            else {
                cell.sActivityIndictor?.hidden = true
                cell.sImageView?.hidden = false
            }
        }
        else {
            peripheralDevice = devicesArrayOnNoSelectedStatus![indexPath.row] as CBPeripheral
            cell.sImageView?.hidden = false
        }
        cell.sTextLabel?.text = "\(peripheralDevice.name)"
        cell.sDetailTextLabel?.text = "\(peripheralDevice.identifier.UUIDString)"
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
        }
        else {
            deviceStatusLabel.text = Util.LocalizedString("Available devices")
            indicatorView = UIActivityIndicatorView(frame: CGRectMake(90, CGPointZero.y, 20,20))
            indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
            tableHeaderView.addSubview(indicatorView)
            if mDeviceCentralManger.isShowAllCanConnectedDevices {
                indicatorView.startAnimating()
                indicatorView.hidden = false
            }
            else
            {
                indicatorView.stopAnimating()
                indicatorView.hidden = true
            }
        }
        return tableHeaderView
        
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        if indexPath.section == 0 {
            currentIndexPathRow = indexPath.row
            var title = Util.LocalizedString("warning")
            var message = Util.LocalizedString("Jump to devices detail page or disConnect this device?")
            var cancelBtnTittle = Util.LocalizedString("Back")
            var otherBtnTitle1 = Util.LocalizedString("DisConnect")
            var otherBtnTitle2 = Util.LocalizedString("Detail Page")
            UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelBtnTittle, otherButtonTitles: otherBtnTitle1, otherBtnTitle2).show()
        }
        else {
            mDeviceCentralManger.userConnectPeripheral(devicesArrayOnNoSelectedStatus![indexPath.row] as CBPeripheral)
        }
    }

    // MARK: - blueTooth do not open
    func deviceCentralManagerBuleToothDoNotOpen() {
        UIAlertView(title: "提示", message: "您iPhone的蓝牙未开启,请开启!", delegate: nil, cancelButtonTitle: "好的").show()
    }

    // MARK: - didChangedCurrentConnectedDevice Delegate
    func central(center: CBCentralManager, unConnectedDevices unConnectedDeviceArr: NSArray, connectedDevices connectedDeviceArr: NSArray) {
        devicesArrayOnSelectedStatus = NSMutableArray(array: connectedDeviceArr)
        devicesArrayOnNoSelectedStatus = NSMutableArray(array: unConnectedDeviceArr)
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
            mDeviceCentralManger.userCancelConnectPeripheral(devicesArrayOnSelectedStatus![currentIndexPathRow] as CBPeripheral)
        }
        else if buttonIndex == 2 {
            println("设备详情")
            performSegueWithIdentifier("peripheralDetailInforimation", sender: self)
        }
    }

    // MARK: - action
    @IBAction func refreshPeripherals(sender: AnyObject) {
        mDeviceCentralManger.isShowAllCanConnectedDevices = true
        mDeviceCentralManger.startScanPeripherals()
        indicatorView.startAnimating()
        indicatorView.hidden = false
    }

    // MARK: - custom method
    func recoverTranslucentedNavigationBar(){
        navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: UIBarMetrics.Default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.barStyle = UIBarStyle.Default
        navigationController?.navigationBar.tintColor = IDOLOGREDCOLOR;
    }

    func recoverTranslucentedTabBar(){
        tabBarController?.tabBar.backgroundImage = nil
        tabBarController?.tabBar.shadowImage = nil
        tabBarController?.tabBar.barStyle = UIBarStyle.Default
        //        tabBarController?.tabBar.translucent = true
        tabBarController?.tabBar.tintColor = IDOLOGREDCOLOR
    }

}
