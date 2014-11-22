//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

class Main: UIViewController, BLEManagerDelegate, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource, UIAlertViewDelegate {
    // MARK: - 🍀 变量
    let segueId = "segue_main_device_list"
    
    var data: [Temp] = []
    var sectionsCount = 5 // 今天的数据(只记录4小时)
    var pageCount = 4
    var pointNumberInsection = 120
    var titleStringArrForXAXis: [String] = [] // 横坐标的string
    var titleStringArrForYMaxPoint = "max"
    
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
        navigationController?.setToolbarHidden(false, animated: false)
        setToolbarStyle(.Transparent)
        let settings = UIBarButtonItem(image: UIImage(named: "ic_action_settings"), style: .Bordered, target: self, action: "settings:")
        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        setToolbarItems([space, settings, space], animated: false)
        
        historyBtn.title = LocalizedString("history")
        peripheralBarBtn.title = LocalizedString("devices")
        numberTaped.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        temperatureLabel.text = LocalizedString("no_device")
        temperatureLabel.font = UIFont(name: "Helvetica", size: 30)
        temperatureLabel.textColor = UIColor.whiteColor()
        dateShow.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        dateShow.text = ""
        reconnectBtn.setTitle(LocalizedString("reconnect"), forState: UIControlState.Normal)
        reconnectBtn.titleLabel?.font = UIFont(name: "Helvetica", size: 30)
        reconnectBtn.hidden = true
        
        BLEManager.sharedManager().delegate = self
        if BLEManager.sharedManager().defaultDevice().isEmpty { // 无绑定设备
            UIAlertView(title: LocalizedString("tips"),
                message: LocalizedString("Please jump to device page to connect device"),
                delegate: self,
                cancelButtonTitle: LocalizedString("cancel"),
                otherButtonTitles: LocalizedString("Jump to device page")).show()
        }
        
        var chart = BEMSimpleLineGraphView(frame: CGRectMake(0, 0, SCREEN_WIDTH * 2, 240))
        chart.delegate = self
        chart.dataSource = self
        // ❨╯°□°❩╯︵┻━┻
        let components: [CGFloat]  = [1, 1, 1, 0.8, 1, 1, 1, 0]
        let locations: [CGFloat] = [0, 0.8]
        chart.gradientBottom = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), components, locations, 2) // 透明化通过Swift转OC会出错
        chart.colorTop = UIColor.clearColor() // 线上颜色
        chart.colorBottom = UIColor.clearColor() // 线下颜色
        chart.colorXaxisLabel = UIColor.whiteColor() // x轴标签色
        chart.colorYaxisLabel = UIColor.whiteColor() // y轴标签色
        chart.enableBezierCurve = true // 贝塞尔曲线
        //        chart.enableTouchReport = true
        chart.enablePopUpReport = true // 包含enableTouchReport效果
        chart.enableYAxisLabel = true // 显示y轴标签
        chart.enableReferenceYAxisLines = true // 显示y轴参考线
        chart.animationGraphStyle = BEMLineAnimation.Fade // 绘制动画关闭会造成PopUp失效
        // ScrollView
        var scrollView = UIScrollView(frame: CGRectMake(0, 200, SCREEN_WIDTH, chart.frame.height + 44))
        scrollView.contentSize = CGSizeMake(chart.frame.width, chart.frame.height)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.addSubview(chart)
        view.addSubview(scrollView)
        
        for i in 0..<12 * 24 {
            var temp = Temp()
            temp.timeStamp = 1
            temp.high = CGFloat(arc4random_uniform(150)) / 100 + 37
            data.append(temp)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarStyle(.Transparent)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        drawChart()
        //        updateCurrentDateLineChart()
    }
    
    // MARK: - 🐤 DeviceStateDelegate
    func didConnect(peripheral: CBPeripheral) {
        temperatureLabel.text = LocalizedString("Connected, waiting for data")
        view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
    }
    
    func didDisconnect() {
        if BLEManager.sharedManager().defaultDevice() != "" {
            temperatureLabel.hidden = true
            reconnectBtn.hidden = false
        } else {
            temperatureLabel.text = LocalizedString("no_device")
            view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
        }
    }
    
    func didUpdateValue(characteristic: CBCharacteristic) {
        let temperature = calculateTemperature(characteristic.value)
        temperatureLabel.text = NSString(format: "%.2f℃", temperature)
        // 保存temperature到数据库
        var temper: Temperature = Temperature()
        temper.high = NSString(format: "%.2f", temperature)
        temper.timeStamp = DateUtils.timestampFromDate(NSDate())
        OliveDBDao.saveTemperature(temper)
        
        drawChart()
        //        updateCurrentDateLineChart()
        
        // 通知
        if temperature <= Util.lowTemperature() { // 温度过低
            view.backgroundColor = UIColor.colorWithHex(IDO_PURPLE)
            if Util.isLowTNotice() {
                sendNotifition("温度过低", temperature: temperature)
            }
        } else if temperature >= Util.HighTemperature() { // 温度过高
            view.backgroundColor = UIColor.colorWithHex(IDO_RED)
            if Util.isHighTNotice() {
                sendNotifition("温度过高", temperature: temperature)
            }
        } else {
            view.backgroundColor = UIColor.colorWithHex(IDO_GREEN)
        }
    }
    
    // MARK:- 💙 BEMSimpleLineGraphDataSource
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView!) -> Int {
        return data.count
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView!, valueForPointAtIndex index: Int) -> CGFloat {
        return data[index].high
    }
    
    // MARK: - 💙 UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 { // 进入设备页
            BLEManager.sharedManager().startScan()
            performSegueWithIdentifier(segueId, sender: self)
        }
    }
    
    @IBAction func reconnectPeripheral(sender: AnyObject) {
        reconnectBtn.hidden = true
        temperatureLabel.hidden = false
        BLEManager.sharedManager().startScan()
    }
    
    // MARK: - 💛 Custom Method
    func drawChart() {
        
    }
    
    // MARK: - 💛 Action
    func settings(sender: AnyObject) {
        performSegueWithIdentifier("segue_home_settings", sender: self)
    }
    
    
    /** generate data */
    func generateChartDataWithDateString(dateStr: String) -> Bool {
        var tempArray: NSMutableArray = OliveDBDao.queryHistoryWithDay(DateUtils.dateFromString(dateStr, withFormat: "yyyy-MM-dd"))
        if tempArray.count == 0 {
            //无数据
            println("无数据")
            return false
        } else {
            //            data = ChartDataConverter().convertDataForToday(tempArray).0
            titleStringArrForXAXis = ChartDataConverter().convertDataForToday(tempArray).1
            return true
        }
    }
    
    func updateCurrentDateLineChart() {
        //默认 显示 lineChart
        let dateStr = DateUtils.stringFromDate(NSDate(), WithFormat: "yyyy-MM-dd")
        if generateChartDataWithDateString(dateStr) {
            // 由数据源改变 eLineChart的值
            var currentGraphChartFrame: CGRect!
            if scrolledChart != nil {
                currentGraphChartFrame = scrolledChart?.frame
                scrolledChart?.removeFromSuperview()
            }
            //            titleStringArrForYMaxPoint = NSString(format: "%.2f", Float(maxValueForLineChart(data)))
            scrolledChart = ScrolledChart(frame: currentGraphChartFrame, pageCount: Float(pageCount), titleInYAXisMax: titleStringArrForYMaxPoint)
            scrolledChart!.scrollView.contentOffset.x = scrolledChart!.scrollView.frame.width * CGFloat(pageCount - 1)
            // add scrollChart
            scrolledChart?.backgroundColor = UIColor.clearColor()
            //            scrolledChart?.lineChart.dataSource = self
            //            scrolledChart?.lineChart.delegate = self
            view.addSubview(scrolledChart!)
            dateShow.text = dateStr
        } else {
            println("无历史数据")
        }
    }
    
    /** 本地通知 */
    func sendNotifition(message: String, temperature: Float) {
        var notification: UILocalNotification! = UILocalNotification()
        if notification != nil {
            notification.fireDate = NSDate().dateByAddingTimeInterval(3)
            notification.timeZone = NSTimeZone.defaultTimeZone()
            notification.alertBody = NSString(format: "请注意：%.2f,%@", temperature, message)
            notification.alertAction = message
            notification.soundName = UILocalNotificationDefaultSoundName // 声音
            notification.applicationIconBadgeNumber = 1 // ???
            notification.userInfo = ["key" : "object"]
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }
    
    func maxValueForLineChart(data: [Int : CGFloat]) -> CGFloat {
        if data.isEmpty {
            fatalError("data为空")
        } else {
            var sortValues = (data.values).array.sorted({$0 > $1})
            return sortValues[0]
        }
        return 0
    }
}
