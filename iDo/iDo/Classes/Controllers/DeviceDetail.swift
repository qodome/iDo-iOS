//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

class DeviceDetail: UITableViewController, DeviceCentralManagerdidChangedCurrentConnectedDeviceDelegate, DeviceCentralManagerDidStartsendDataDelegate, DeviceCentralManagerBuleToothDoNotOpenDelegate, UIAlertViewDelegate {

    let IDOLOGREDCOLOR = Util.ColorFromRGB(0xFB414D)
    let deviceCellIdentity = "deviceCell"

    var devicesArrayOnSelectedStatus: NSMutableArray?
    var devicesArrayOnNoSelectedStatus: NSMutableArray?
    var mDeviceCentralManger: DeviceCentralManager!

    var indicatorView:UIActivityIndicatorView!
    var currentIndexPathRow:Int = -1 //不好

    @IBOutlet weak var refreshBarBtn: UIBarButtonItem!

    //MARK: - life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshBarBtn.title = NSLocalizedString("refresh", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
        navigationItem.title = NSLocalizedString("peripheral", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
        recoverTranslucentedNavigationBar()
        recoverTranslucentedTabBar()
       
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
            mDeviceCentralManger.stopScanPeripherals() // 有问题
            mDeviceCentralManger.isShowAllCanConnectedDevices = false
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "peripheralDetailInforimation" {
            var detailInforVC = segue.destinationViewController as DeviceList
            detailInforVC.currentPeripheral = devicesArrayOnSelectedStatus![currentIndexPathRow] as CBPeripheral
        }
        
    }

    // MARK: - tableView DataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if 0 == section {
            return devicesArrayOnSelectedStatus!.count
        }
        return devicesArrayOnNoSelectedStatus!.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:PeripheralSelectedTableViewCell = tableView.dequeueReusableCellWithIdentifier(deviceCellIdentity , forIndexPath: indexPath) as PeripheralSelectedTableViewCell
        
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

    // MARK: - tableView Delegate
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
            deviceStatusLabel.text =  NSLocalizedString("Connected devices", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
        }
        else {
            deviceStatusLabel.text = NSLocalizedString("Available devices", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
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
            var title = NSLocalizedString("warning", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
            var message = NSLocalizedString("Jump to devices detail page or disConnect this device?", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
            var cancelBtnTittle = NSLocalizedString("Back", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
            var otherBtnTitle1 = NSLocalizedString("DisConnect", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
            var otherBtnTitle2 = NSLocalizedString("Detail Page", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
            UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelBtnTittle, otherButtonTitles: otherBtnTitle1, otherBtnTitle2).show()
        }
        else {
            mDeviceCentralManger.userConnectPeripheral(devicesArrayOnNoSelectedStatus![indexPath.row] as CBPeripheral)
        }
    }

    // Mark: - blueTooth do not open
    func deviceCentralManagerBuleToothDoNotOpen() {
        UIAlertView(title: "提示", message: "您iPhone的蓝牙未开启,请开启!", delegate: nil, cancelButtonTitle: "好的").show()
    }

    // MARK: - didChangedCurrentConnectedDevice Delegate
    func central(center: CBCentralManager, unConnectedDevices unConnectedDeviceArr: NSArray, connectedDevices connectedDeviceArr: NSArray) {
        devicesArrayOnSelectedStatus = NSMutableArray(array: connectedDeviceArr)
        devicesArrayOnNoSelectedStatus = NSMutableArray(array: unConnectedDeviceArr)
        tableView.reloadData()
    }

    //MARK: -  DeviceCentralManager DidStartsendData Delegate
    func deviceCentralManagerDidStartsendData() {
        //停止loading
        tableView.reloadData()
    }

    //MARK: - uiAlertView Delegate
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

    //MARK: - custom method
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
