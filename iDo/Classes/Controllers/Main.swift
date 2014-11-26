//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

class Main: UIViewController, BLEManagerDelegate, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource, UIAlertViewDelegate {
    // MARK: - 🍀 变量
    let segueId = "segue_main_device_list"
    var data: [Temp] = []
    
    var scrollView: UIScrollView!
    var chart: BEMSimpleLineGraphView!
    
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
        // 第一次进来
        let defaults = NSUserDefaults.standardUserDefaults()
        if defaults.boolForKey("inited") {
            Util.setIsHighTNotice(true)
            defaults.setBool(true, forKey: "inited")
        } 
        BLEManager.sharedManager().delegate = self
        if BLEManager.sharedManager().defaultDevice().isEmpty { // 无绑定设备
            UIAlertView(title: LocalizedString("tips"),
                message: LocalizedString("Please jump to device page to connect device"),
                delegate: self,
                cancelButtonTitle: LocalizedString("cancel"),
                otherButtonTitles: LocalizedString("Jump to device page")).show()
        }
        
        chart = BEMSimpleLineGraphView(frame: CGRectMake(0, 0, SCREEN_WIDTH * 2, 240))
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
        // chart.enableBezierCurve = true // 贝塞尔曲线，连续两点相同会造成误导
        chart.enablePopUpReport = true // 包含enableTouchReport效果
        chart.enableYAxisLabel = true // 显示y轴标签
        chart.enableReferenceYAxisLines = true // 显示y轴参考线
        chart.animationGraphStyle = BEMLineAnimation.Fade // 绘制动画关闭会造成PopUp失效
        // ScrollView
        scrollView = UIScrollView(frame: CGRectMake(0, 200, SCREEN_WIDTH, chart.frame.height + 44))
        scrollView.contentSize = CGSizeMake(chart.frame.width, scrollView.frame.height)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.addSubview(chart)
        view.addSubview(scrollView)
        
        // 获取温度值
        let value: CGFloat = CGFloat(arc4random_uniform(150)) / 100 + 37 // 生成假数据
        // 比对时间
        let now = NSDate() // 当前时间
        let calendar = NSCalendar.autoupdatingCurrentCalendar()
        let dateComponents = calendar.components(.YearCalendarUnit | .MonthCalendarUnit | .DayCalendarUnit, fromDate: now)
        dateComponents.timeZone = NSTimeZone(name: "UTC")
        let midnight = calendar.dateFromComponents(dateComponents)! // 一天的开始
        let timeInterval = now.timeIntervalSince1970
        let minute = NSDate(timeIntervalSince1970: timeInterval - (timeInterval - midnight.timeIntervalSince1970) % 300) // 5分钟频率
        println("=========")
        println(midnight)
        println(minute)
        println(value)
        println("=========")
        var temp = Temp()
        temp.timeStamp = Int(minute.timeIntervalSince1970)
        temp.open = value
        temp.high = value
        temp.low = value
        temp.close = value
        
        let previous = NSUserDefaults.standardUserDefaults().objectForKey("temperature")
        if previous != nil {
            let p = previous as NSArray
            let previousTime = Int(p[0] as NSNumber)
            if (temp.timeStamp - previousTime) < 300 { // 如果不到5分钟
                temp.timeStamp = previousTime
                temp.open = CGFloat(p[1] as NSNumber) // open为之前存储的值
                temp.high = max(CGFloat(p[2] as NSNumber), value)
                temp.low = min(CGFloat(p[3] as NSNumber), value)
            }
        }
        let json = "[\(temp.timeStamp),\(temp.open),\(temp.high),\(temp.low),\(temp.close)]"
        let current = NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding)!, options: .allZeros, error: nil) as NSArray
        NSUserDefaults.standardUserDefaults().setObject(current, forKey: "temperature") // 写历史记录
        // 写历史数据
        let format = NSDateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let path = paths[0].stringByAppendingPathComponent("temperature/\(format.stringFromDate(midnight)).json")
        let file = NSFileHandle(forUpdatingAtPath: path)
        if file == nil {
            NSFileManager.defaultManager().createDirectoryAtPath(path.stringByDeletingLastPathComponent, withIntermediateDirectories: false, attributes: nil, error: nil) // 创建目录
            NSFileManager.defaultManager().createFileAtPath(path, contents: "[\(json)]".dataUsingEncoding(NSUTF8StringEncoding), attributes: nil) // 创建文件
        } else { // (不到5分钟，替换，超过5分钟，新增)
            var index = file?.seekToEndOfFile()
            file?.seekToFileOffset(index! - 1)
            file?.writeData(",\(json)]".dataUsingEncoding(NSUTF8StringEncoding)!)
            file?.closeFile()
        }
        println("==================")
        println(current)
        println("==================")
        println(previous)
        println("==================")
        // 取历史数据
        if file != nil {
            let json = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
            println(json)
            let content = NSJSONSerialization.JSONObjectWithData(json!.dataUsingEncoding(NSUTF8StringEncoding)!, options: .allZeros, error: nil) as NSArray
            for d in content {
                var temperature = Temp()
                temperature.timeStamp = Int(d[0] as NSNumber)
                temperature.high = CGFloat(d[2] as NSNumber)
                data.append(temperature)
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarStyle(.Transparent)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
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
        temperatureLabel.text = NSString(format: "%.2f°", temperature)
        // 保存temperature到数据库
        var temper: Temperature = Temperature()
        temper.high = NSString(format: "%.2f", temperature)
        temper.timeStamp = DateUtils.timestampFromDate(NSDate())
        OliveDBDao.saveTemperature(temper)
        // 保存到本地文件
        
        drawChart()
        //        updateCurrentDateLineChart()
        // 通知
        let defautls = NSUserDefaults.standardUserDefaults()
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
        return CGFloat(data[index].high)
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
        chart.frame.size = CGSizeMake(SCREEN_WIDTH * 2, chart.frame.height)
        scrollView.contentSize = CGSizeMake(chart.frame.width, scrollView.frame.height)
        chart.reloadGraph()
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
}
