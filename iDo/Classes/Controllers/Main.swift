//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

class Main: UIViewController, DeviceCentralManagerConnectedStateChangeDelegate, CalendarViewDelegate, FDCaptionGraphViewDelegate, UIAlertViewDelegate, UIScrollViewDelegate {

    let segueId = "mPeriphalSegue"
    let kSCREEN_WIDTH = UIScreen.mainScreen().bounds.size.width
    let kSCREEN_HEIGHT = UIScreen.mainScreen().bounds.size.height
    let kNAVIGATIONBAR_HEIGHT: CGFloat = 64.0 //优化

    let IDOGREENCOLOR = UIColor.colorWithHex(0x17A865)
    let IDOPURPLECOLOR = UIColor.colorWithHex(0xAA66CC)
    let IDOBLUECOLOR = UIColor.colorWithHex(0x2897C3)
    let IDOORANGECOLOR = UIColor.colorWithHex(0xE24424)
    let IDOLOGREDCOLOR = UIColor.colorWithHex(0xFB414D)

    var mDeviceCentralManger: DeviceCentralManager!
    var lineChartData: NSArray! // 折线图数据data

    var isCurrentDateHaveLineChartData = true

    var calendarView: CalendarView? // 日历View
    @IBOutlet weak var settingBtn: UIButton!
    @IBOutlet weak var peripheralBarBtn: UIBarButtonItem!
    @IBOutlet weak var calenderBtn: UIBarButtonItem!
    @IBOutlet weak var numberTaped: UILabel! //显示当前温度的label
    @IBOutlet weak var dateShow: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel! //显示折线图中当前点值的label
    @IBOutlet weak var reconnectBtn: UIButton!
    @IBOutlet var graphChart: FDGraphScrollView? // 折线图View

    var currentSelectedDateString: NSString = DateUtil.stringFromDate(NSDate(), WithFormat: "yyyy-MM-dd")

    // MARK: - 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        settingBtn.setTitle(LocalizedString("settings"), forState: UIControlState.Normal)
        calenderBtn.title = LocalizedString("calendar")
        peripheralBarBtn.title = LocalizedString("devices")
        numberTaped.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        temperatureLabel.text = LocalizedString("finding a device")
        temperatureLabel.font = UIFont(name: "Helvetica", size: 30)
        dateShow.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        dateShow.text = ""
        reconnectBtn.setTitle(LocalizedString("reconnect"), forState: UIControlState.Normal)
        reconnectBtn.titleLabel?.font = UIFont(name: "Helvetica", size: 30)
        reconnectBtn.hidden = true
        view.backgroundColor = IDOBLUECOLOR
        
        mDeviceCentralManger = DeviceCentralManager.instanceForCenterManager()
        mDeviceCentralManger.characteristicDelegate = self
        if mDeviceCentralManger.lastConnectedPeripheralUUID().isEmpty { // 无绑定设备
            isCurrentDateHaveLineChartData = false
            var title = LocalizedString("Prompt")
            var message = LocalizedString("Please jump to device page to connect device")
            var cancelBtnTittle = LocalizedString("Cancel")
            var otherBtnTitle = LocalizedString("Jump to device page")
            UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancelBtnTittle, otherButtonTitles: otherBtnTitle).show()
        }
        graphChart?.hidden = true
        graphChart?.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // 透明化navigationBar
        translucentNavigationBar()
        translucentTabBar()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateCurrentDateLineChart()
    }

    // MARK: -  DeviceCentralManagerConnectedStateChangeDelegate
    func centralManger(centralManger: CBCentralManager, didAutoDisConnectedPeripheral connectingPeripheral: CBPeripheral) {
        temperatureLabel.hidden = true
        reconnectBtn.hidden = false
    }
    
    func centralManger(centralManger: CBCentralManager, didConnectedPeripheral connectingPeripheral: CBPeripheral) {
        temperatureLabel.text = LocalizedString("Connected, waiting for data")
        view.backgroundColor = IDOBLUECOLOR
    }
    
    
    func didUpdateValueToCharacteristic(characteristic:CBCharacteristic? ,cError error:NSError?) {
        if characteristic == nil && error == nil {
            temperatureLabel.text = LocalizedString("finding a device")
            view.backgroundColor = IDOBLUECOLOR
            return
        }
        println("data length----\(characteristic?.value.length)")
        if characteristic?.value.length == 5 && error == nil {
            // 写date数据到peripheral中
            // 得到当前data的16进制
            var dateString: NSString = DateUtil.stringFromDate(NSDate(), WithFormat: "yyyyMMddHHmmss")
            
            let mWriteData: NSData = (dateString.dataUsingEncoding(NSASCIIStringEncoding))!
            var bytes = [UInt8](count: mWriteData.length, repeatedValue: 0)
            mWriteData.getBytes(&bytes, length:mWriteData.length)
            var mDateBytes = [UInt8](count: mWriteData.length/2, repeatedValue: 0)
            for var i = 0; i < bytes.count; i++ {
                // [NSString stringWithFormat:@"%x",bytes[i]&0xff]
                var cData = NSString(format: "%c%c", bytes[i],bytes[i+1]).integerValue
                i++
                mDateBytes[i/2] = UInt8(cData)
                println("write data length\(cData)")
            }
            var hexArr:NSMutableArray = NSMutableArray()
            var writeDataString: String = ""
            for var i = 0; i < mDateBytes.count; i++ {
                var hexStr: NSString = ""
                var newHexStr: NSString =  NSString(format: "%x", mDateBytes[i]&0xff)
                if newHexStr.length == 1 {
                    hexStr = NSString(format: "%@0%@", hexStr, newHexStr)
                } else {
                    hexStr = NSString(format: "%@%@", hexStr, newHexStr)
                }
                println("1 mDateBytes: \(mDateBytes[i])")
                hexArr[i] = hexStr
                writeDataString += hexStr
                println("2 mDateBytes: \(hexArr[i])")
            }
            println("writeDataString-\(writeDataString)")
            let realWriteData = writeDataString.dataUsingEncoding(NSASCIIStringEncoding)!
            var mRealDateBytes = [UInt8](count: realWriteData.length/2, repeatedValue: 0)
            for var i = 0; i < bytes.count; i++ {
                var cData = NSString(format: "%c%c", bytes[i],bytes[i+1]).integerValue
                i++
                mDateBytes[i/2] = UInt8(cData)
                println("2 write data length\(cData)")
            }
            let mRealWriteData = NSData(bytes: mRealDateBytes, length: mRealDateBytes.count)
            //println("realWriteData--\(realWriteData.description) length--\(realWriteData.length)")
            //writeData(mDeviceCentralManger.devicesArrayOnSelectedStatus[0] as CBPeripheral, forCharacteristic:characteristic! , forData:mRealWriteData)
        }
        // 得到temperature
        var temperature = calculateTemperatureData(mDeviceCentralManger.devicesArrayOnSelectedStatus[0] as CBPeripheral, forCharacteristic:characteristic! , forData: characteristic?.value)
        temperatureLabel.text = NSString(format: "%.2f°C", temperature)
        // 保存temperature到数据库
        var temper: Temperature = Temperature()
        temper.cTemperature = NSString(format: "%.2f", temperature)
        temper.cDate = DateUtil.timestampFromDate(NSDate())
        OliveDBDao.saveTemperature(temper)
        if currentSelectedDateString == DateUtil.stringFromDate(NSDate(), WithFormat: "yyyy-MM-dd") {
            updateCurrentDateLineChart()
        }
        // 通知相关
        if temperature < Util.lowestTemperature() {
            // 温度过低
            if Util.isLowTNotice() {
                println("温度过低")
                view.backgroundColor = IDOPURPLECOLOR
                sendTemperatureNotifition("温度过低", nowTemperature: temperature)
            } else {
                println("还原颜色")
                //还原颜色
                view.backgroundColor = IDOGREENCOLOR
            }
        } else if temperature > Util.HighestTemperature() {
            //温度过高
            if Util.isHighTNotice() {
                println("温度过高")
                view.backgroundColor = IDOORANGECOLOR
                sendTemperatureNotifition("温度过高", nowTemperature: temperature)
            } else {
                println("还原颜色")
                //还原颜色
                view.backgroundColor = IDOGREENCOLOR
            }
        } else {
            println("还原颜色")
            // 还原颜色
            view.backgroundColor = IDOGREENCOLOR
        }

    }

    // MARK: - UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 { //进入设备页
            mDeviceCentralManger.startScan()
            performSegueWithIdentifier(segueId, sender: self)
        }
    }

    // MARK: -  calendarView Delegate
    func didSelectDate(dateStr: String, forDetail enty: WeekEntity) {
        println("did selected date - \(dateStr)")
        dismissCalenderAction()
        // 根据date 从数据中取出温度记录 就是eLineChart的数据源
        if generateChartDataWithDateString(dateStr) {
            // 由数据源改变 eLineChart的值
            initSubViewToView()
            numberTaped.text = " "
            dateShow.text = dateStr
            currentSelectedDateString = dateStr
        } else {
            var title = LocalizedString("Prompt")
            var message = LocalizedString("Don't have any data on the day !")
            var cancelBtnTittle = LocalizedString("Done")
            UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: cancelBtnTittle).show()
        }
    }

    // MARK: -  fdGraphView Delegate
    func tapedCloserIndex(index: Int32, withPointX PointX: CGFloat) {
        numberTaped.hidden = false
        println("tapedCloserIndex-\(lineChartData[Int(index)])")
        var tapedTemperature = lineChartData[Int(index)] as Temperature
        println("currentDate-\(NSDate())")
        let dateStr = DateUtil.stringFromDate( NSDate(timeIntervalSince1970: NSTimeInterval(tapedTemperature.cDate.doubleValue / 1000)), WithFormat:"yyyy-MM-dd HH:mm:ss ")
        //numberTaped.text =  NSString(format: "%@°C  %@",tapedTemperature.cTemperature,dateStr)
        numberTaped.text =  NSString(format: "%@°C",tapedTemperature.cTemperature)
    }

    // MARK: - scrollView Delegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        numberTaped.hidden = true
    }

    // MARK: -  Action
    @IBAction func showCalenderView(sender: AnyObject) {
        if (calendarView != nil) {
            dismissCalenderAction()
        } else {
            var settingBtnHeight = settingBtn.frame.height
            calendarView = CalendarView(frame: CGRectMake(0, kNAVIGATIONBAR_HEIGHT, 225, kSCREEN_HEIGHT - kNAVIGATIONBAR_HEIGHT - settingBtnHeight))
            if graphChart == nil {
                view.addSubview(calendarView!)
            } else {
                view.insertSubview(calendarView!, aboveSubview: graphChart!)
            }
            calendarView?.delegate = self
        }
    }
    
    @IBAction func reconnectPeripheral(sender: AnyObject) {
        reconnectBtn.hidden = true
        temperatureLabel.hidden = false
        mDeviceCentralManger.startScan()
    }

    // MARK: - Custom Method
    func dismissCalenderAction() {
        calendarView?.removeFromSuperview()
        calendarView?.delegate = nil
        calendarView = nil
    }

    func translucentNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.barStyle = UIBarStyle.Black
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        temperatureLabel.textColor = UIColor.whiteColor()
    }

    func translucentTabBar() {
        tabBarController?.tabBar.backgroundImage = UIImage()
        tabBarController?.tabBar.shadowImage = UIImage()
        tabBarController?.tabBar.barStyle = UIBarStyle.Black
        tabBarController?.tabBar.translucent = true
        tabBarController?.tabBar.tintColor = UIColor.whiteColor()
    }

    func initSubViewToView() {
        var currentGraphChartFrame: CGRect!
        if graphChart != nil {
            currentGraphChartFrame = graphChart?.frame
            graphChart?.removeFromSuperview()
            graphChart?.fDGraphViewDelegate = nil
        }
        println("currentFrame - \(currentGraphChartFrame)")
        graphChart = FDGraphScrollView(frame: currentGraphChartFrame)
        addGraphLineChart()
    }

    func addGraphLineChart() {
       // println("viewHeight- \(view.frame.size.height) \(graphChart?.frame)")
        graphChart?.backgroundColor = UIColor.clearColor()
        graphChart?.fDGraphViewDelegate = self
        graphChart?.delegate = self // scrollViewDelegate
        // 必须现设 numberOfDataPointsInEveryPage 在设 dataPoints
        graphChart?.numberOfDataPointsInEveryPage = 100
        var lineFloatData = NSMutableArray()
        for var i = 0; i < lineChartData.count; i++ {
            var cTemp = lineChartData[i] as Temperature
            lineFloatData.addObject(cTemp.cTemperature.floatValue)
        }
        graphChart?.setDataPoints(lineFloatData)
        graphChart?.dataPointColorAfterTaped = UIColor.whiteColor()
        if calendarView == nil {
            view.addSubview(graphChart!)
        } else {
             view.insertSubview(graphChart!, belowSubview: calendarView!)
        }
    }

    /** generate data */
    func generateChartDataWithDateString(dateStr: String) ->Bool {
        var tempArray: NSMutableArray = OliveDBDao.queryHistoryWithDay(DateUtil.dateFromString(dateStr, withFormat: "yyyy-MM-dd"))
        if tempArray.count == 0 {
            //无数据
            println("无数据")
            return false
        } else {
            var tempChartDataArr = NSMutableArray()
            var i = 0
            for number in tempArray {
                let mTemperature = number as Temperature
                //tempChartDataArr.addObject(mTemperature.cTemperature.floatValue)
                tempChartDataArr.addObject(mTemperature)
            }
            lineChartData = NSArray(array: tempChartDataArr)
            return true
        }
    }

    func updateCurrentDateLineChart() {
        //默认 显示 lineChart
        let dateStr = DateUtil.stringFromDate(NSDate(), WithFormat: "yyyy-MM-dd")
        if generateChartDataWithDateString(dateStr) {
            // 由数据源改变 eLineChart的值
            initSubViewToView()
            graphChart?.hidden = false
            dateShow.text = dateStr
        } else {
            println("无历史数据")
        }
    }

    /** About notifition */
    func sendTemperatureNotifition(notifictionMessage: String, nowTemperature temperature: Float) {
        var notification: UILocalNotification! = UILocalNotification()
        if notification != nil {
            notification.fireDate = NSDate().dateByAddingTimeInterval(3)
            notification.timeZone = NSTimeZone.defaultTimeZone()
            notification.alertBody = NSString(format: "请注意：%.2f,%@", temperature, notifictionMessage)
            notification.alertAction = notifictionMessage
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.applicationIconBadgeNumber = 1 //???
            notification.userInfo = ["key":"object"]
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }

    /** 处理蓝牙传来的data */
    func calculateTemperatureData(currrentPeripheral :CBPeripheral, forCharacteristic currentCharacteristic:CBCharacteristic, forData data: NSData?) ->Float {
        println("bytes--\(data?.length)")
        var bytes = [UInt8](count: 5, repeatedValue: 0)
        data?.getBytes(&bytes, length:5)
        var byte0 = bytes[0]
        println("byte0:\(bytes[0])")
        var exponent = bytes[4] // -4
        var fuzhiExponent = Float (-(255 - exponent)-1) //?
        var b3 = Int32(bytes[3])
        var mantissa = ( Int32(bytes[3]) << 16) | (Int32(bytes[2]) << 8) | Int32(bytes[1])
        println("mantissa--\(mantissa)")
        let temperature = Float (mantissa) * Float(pow(10.0, fuzhiExponent))
        return temperature
    }

    /** 写date数据到peripheral中 */
    func writeData(currrentPeripheral :CBPeripheral, forCharacteristic currentCharacteristic:CBCharacteristic, forData data: NSData) {
        currrentPeripheral.writeValue(data, forCharacteristic: currentCharacteristic, type:CBCharacteristicWriteType.WithResponse)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        (segue.destinationViewController as UIViewController).hidesBottomBarWhenPushed = true
    }

}
