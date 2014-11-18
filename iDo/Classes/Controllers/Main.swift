//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth
import UIKit

class Main: UIViewController, BLEManagerDelegate, UIAlertViewDelegate, UIScrollViewDelegate, ScrolledChartDelegate, ScrolledChartDataSource {
    // MARK: - 🍀 变量
    let segueId = "segue_main_device_list"
    
    var deviceManager: BLEManager!
    var data: [Int : CGFloat] = Dictionary()
    var sectionsCount = 5 //今天的数据(只记录4小时)
    var pageCount = 4
    var pointNumberInsection = 120
    var titleStringArrForXAXis: [String] = [] // 横坐标的string
    var titleStringArrForYMaxPoint = "max"
    var currentSelectedDateString: NSString = DateUtil.stringFromDate(NSDate(), WithFormat: "yyyy-MM-dd")
    
    @IBOutlet weak var settingBtn: UIButton!
    @IBOutlet weak var peripheralBarBtn: UIBarButtonItem!
    @IBOutlet weak var historyBtn: UIBarButtonItem!
    @IBOutlet weak var numberTaped: UILabel! //显示当前温度的label
    @IBOutlet weak var dateShow: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel! //显示折线图中当前点值的label
    @IBOutlet weak var reconnectBtn: UIButton!
    @IBOutlet var scrolledChart: ScrolledChart?
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
        settingBtn.setTitle(LocalizedString("settings"), forState: UIControlState.Normal)
        historyBtn.title = LocalizedString("history")
        peripheralBarBtn.title = LocalizedString("devices")
        numberTaped.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        temperatureLabel.text = LocalizedString("finding a device")
        temperatureLabel.font = UIFont(name: "Helvetica", size: 30)
        dateShow.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        dateShow.text = ""
        reconnectBtn.setTitle(LocalizedString("reconnect"), forState: UIControlState.Normal)
        reconnectBtn.titleLabel?.font = UIFont(name: "Helvetica", size: 30)
        reconnectBtn.hidden = true
        
        deviceManager = BLEManager.sharedManager()
        deviceManager.delegate = self
        if deviceManager.defaultDevice().isEmpty { // 无绑定设备
            UIAlertView(title: LocalizedString("tips"),
                message: LocalizedString("Please jump to device page to connect device"),
                delegate: self,
                cancelButtonTitle: LocalizedString("cancel"),
                otherButtonTitles: LocalizedString("Jump to device page")).show()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // 透明化navigationBar
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.barStyle = UIBarStyle.Black
        navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        temperatureLabel.textColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateCurrentDateLineChart()
    }
    
    // MARK: - DeviceStateDelegate
    func didConnect(centralManger: CBCentralManager, peripheral: CBPeripheral) {
        temperatureLabel.text = LocalizedString("Connected, waiting for data")
        view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
    }
    
    func didDisconnect(centralManger: CBCentralManager, peripheral: CBPeripheral) {
        temperatureLabel.hidden = true
        reconnectBtn.hidden = false
    }
    
    func didUpdateValue(characteristic: CBCharacteristic?, error: NSError?) {
        if characteristic == nil && error == nil {
            temperatureLabel.text = LocalizedString("finding a device")
            view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
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
            for i in 0..<mDateBytes.count {
                var hexStr: NSString = ""
                var newHexStr: NSString = NSString(format: "%x", mDateBytes[i]&0xff)
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
        var temperature = calculateTemperature(characteristic!.value)
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
        if temperature <= Util.lowTemperature() { // 温度过低
            view.backgroundColor = UIColor.colorWithHex(IDO_PURPLE)
            if Util.isLowTNotice() {
                println("温度过低")
                sendNotifition("温度过低", temperature: temperature)
            }
        } else if temperature >= Util.HighTemperature() { // 温度过高
            view.backgroundColor = UIColor.colorWithHex(IDO_ORANGE)
            if Util.isHighTNotice() {
                println("温度过高")
                sendNotifition("温度过高", temperature: temperature)
            }
        } else {
            view.backgroundColor = UIColor.colorWithHex(IDO_GREEN)
        }
    }
    
    // MARK: - 💙 UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 { //进入设备页
            deviceManager.startScan()
            performSegueWithIdentifier(segueId, sender: self)
        }
    }
    
    // MARK: - 💙 UIScrollViewDelegate
    func scrollViewDidScroll(scrollView: UIScrollView) {
        numberTaped.hidden = true
    }
    
    // MARK: - ScrolledChartDataSource
    func numberOfSectionsInScrolledChart(scrolledChart: LineChart) ->Int {
        return sectionsCount
    }
    
    func allNumberOfPointsInSection(scrolledChart: LineChart) ->Int {
        return pointNumberInsection
    }
    
    func numberOfPointsInScrolledChart(scrolledChart: LineChart) ->Int {
        return data.values.array.count
    }
    
    func scrolledChart(scrolledChart: LineChart, keyForItemAtPointNumber pointNumber: Int) ->Int {
        var sortKeys = (data.keys).array.sorted({$0 < $1})
        return sortKeys[pointNumber]
    }
    
    func scrolledChart(scrolledChart: LineChart, valueForItemAtKey key: Int) ->CGFloat {
        return data[key]!
    }
    
    func maxDataInScrolledChart(scrolledChart: LineChart) ->CGFloat {
        return maxValueForLineChart(data)
    }
    
    func scrolledChart(scrolledChart: LineChart, titleInXAXisPointLabelInSection section: Int) ->String {
        return titleStringArrForXAXis[section]
    }
    
    // MARK: - ScrolledChartDelegate
    func scrolledChart(scrolledChart: LineChart, didClickItemAtPointNumber pointNumber: Int) {
        //println("data - \(data.description)")
        println("didClickItemAtIndexPath")
        numberTaped.text = NSString(format: "%.2f°C", Float(data[pointNumber]!))
    }
    
    @IBAction func reconnectPeripheral(sender: AnyObject) {
        reconnectBtn.hidden = true
        temperatureLabel.hidden = false
        deviceManager.startScan()
    }
    
    // MARK: - Custom Method
    func initSubViewToView() {
        var currentGraphChartFrame: CGRect!
        if scrolledChart != nil {
            currentGraphChartFrame = scrolledChart?.frame
            scrolledChart?.removeFromSuperview()
        }
        titleStringArrForYMaxPoint = NSString(format: "%.2f", Float(maxValueForLineChart(data)))
        scrolledChart = ScrolledChart(frame: currentGraphChartFrame, pageCount: Float(pageCount), titleInYAXisMax: titleStringArrForYMaxPoint)
        scrolledChart!.scrollView.contentOffset.x = scrolledChart!.scrollView.frame.width * CGFloat(pageCount - 1)
        // add scrollChart
        scrolledChart?.backgroundColor = UIColor.clearColor()
        scrolledChart?.lineChart.dataSource = self
        scrolledChart?.lineChart.delegate = self
        view.addSubview(scrolledChart!)
    }
    
    /** generate data */
    func generateChartDataWithDateString(dateStr: String) -> Bool {
        var tempArray: NSMutableArray = OliveDBDao.queryHistoryWithDay(DateUtil.dateFromString(dateStr, withFormat: "yyyy-MM-dd"))
        if tempArray.count == 0 {
            //无数据
            println("无数据")
            return false
        } else {
            data = ChartDataConverter().convertDataForToday(tempArray).0
            titleStringArrForXAXis = ChartDataConverter().convertDataForToday(tempArray).1
            return true
        }
    }
    
    func updateCurrentDateLineChart() {
        //默认 显示 lineChart
        let dateStr = DateUtil.stringFromDate(NSDate(), WithFormat: "yyyy-MM-dd")
        if generateChartDataWithDateString(dateStr) {
            // 由数据源改变 eLineChart的值
            initSubViewToView()
            dateShow.text = dateStr
        } else {
            println("无历史数据")
        }
    }
    
    /** About notifition */
    func sendNotifition(message: String, temperature: Float) {
        var notification: UILocalNotification! = UILocalNotification()
        if notification != nil {
            notification.fireDate = NSDate().dateByAddingTimeInterval(3)
            notification.timeZone = NSTimeZone.defaultTimeZone()
            notification.alertBody = NSString(format: "请注意：%.2f,%@", temperature, message)
            notification.alertAction = message
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.applicationIconBadgeNumber = 1 //???
            notification.userInfo = ["key":"object"]
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }
    
    
    
    /** 写date数据到peripheral中 */
    func writeValue(peripheral: CBPeripheral, data: NSData, characteristic: CBCharacteristic) {
        peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
    }
    
    func maxValueForLineChart(data: [Int : CGFloat]) -> CGFloat {
        if data.isEmpty  {
            fatalError("data为空")
        }
        var sortValues = (data.values).array.sorted({$0 > $1})
        return sortValues[0]
    }
}
