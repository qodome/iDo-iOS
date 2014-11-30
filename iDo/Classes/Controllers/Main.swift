//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Main: UIViewController, BLEManagerDelegate, BLEManagerDataSource, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource, UIAlertViewDelegate {
    // MARK: - 🍀 变量
    let segueId = "segue_main_device_list"
    var data: [Temperature] = []
    
    var json = "" // 历史数据json
    
    var scrollView: UIScrollView!
    var chart: BEMSimpleLineGraphView!
    
    @IBOutlet weak var numberTaped: UILabel! //显示当前温度的label
    @IBOutlet weak var dateShow: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel! //显示折线图中当前点值的label
    @IBOutlet weak var reconnectBtn: UIButton!
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: LocalizedString("history"), style: .Bordered, target: self, action: "history:")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocalizedString("devices"), style: .Bordered, target: self, action: "devices:")
        navigationController?.setToolbarHidden(false, animated: false)
        setToolbarStyle(.Transparent)
        let settings = UIBarButtonItem(image: UIImage(named: "ic_action_settings"), style: .Bordered, target: self, action: "settings:")
        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        setToolbarItems([space, settings, space], animated: false)

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
        BLEManager.sharedManager().dataSource = self
        
        chart = BEMSimpleLineGraphView(frame: CGRectMake(0, 0, view.frame.width * 2, 240))
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
        // ScrollView
        scrollView = UIScrollView(frame: CGRectMake(0, 200, view.frame.width, chart.frame.height + 44))
        scrollView.contentSize = CGSizeMake(chart.frame.width, scrollView.frame.height)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.addSubview(chart)
        view.addSubview(scrollView)
        // 取当天的历史数据
        let path = getHistory(NSDate())
        let file = NSFileHandle(forUpdatingAtPath: path)
        var content: NSArray = []
        if file != nil {
            json = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
            let content = NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding)!, options: .allZeros, error: nil) as NSArray
            for d in content {
                let temperature = Temperature()
                temperature.timeStamp = Int(d[0] as NSNumber)
                temperature.open = Float(d[1] as NSNumber)
                temperature.high = Float(d[2] as NSNumber)
                temperature.low = Float(d[3] as NSNumber)
                temperature.close = Float(d[3] as NSNumber)
                data.append(temperature)
            }
        }
        setChartSize() // 要放在加载数据之后
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarStyle(.Transparent)
        // TODO: 在设置中断开连接后，回这个界面，需要更新状态
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if BLEManager.sharedManager().defaultDevice() == nil { // 无绑定设备
//            UIAlertView(title: "",
//                message: LocalizedString("choose_device"),
//                delegate: self,
//                cancelButtonTitle: LocalizedString("cancel"),
//                otherButtonTitles: LocalizedString("ok")).show()
        }
    }
    
    // MARK: - 🐤 BLEManagerDelegate
    func onStateChanged(state: BLEManagerState, peripheral: CBPeripheral?) {
        switch state {
        case .PowerOff:
            println()
        case .Idle:
            println()
        case .Scan, .Discovered:
            println()
        case .Connecting, .Connected:
            println()
        case .ServiceDiscovered:
            temperatureLabel.text = LocalizedString("connected")
            view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
        case .Disconnected:
            if BLEManager.sharedManager().defaultDevice() == nil {
                temperatureLabel.text = LocalizedString("no_device")
                view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
            } else {
                temperatureLabel.hidden = true
                reconnectBtn.hidden = false
            }
        case .Fail:
            println()
        default:
            Log("Unknown State: \(state.rawValue)")
        }
    }
    
    // MARK: - 🐤 BLEManagerDataSource
    func onUpdateValue(characteristic: CBCharacteristic?) {
        // 获取温度值
        var value: Float
        if characteristic != nil {
            value = Float(calculateTemperature(characteristic!.value))
        } else {
            value = Float(arc4random_uniform(150)) / 100 + 37 // 生成假数据
        }
        temperatureLabel.text = NSString(format: "%.2f°", value)
        // 初始化一个温度对象
        let temp = Temperature()
        temp.timeStamp = getTimeStamp(NSDate(), minute: 5) // 当前时间最接近的5分钟频率
        temp.open = value
        temp.high = value
        temp.low = value
        temp.close = value
        // 比对历史数据
        let last = data.last
        if last != nil {
            if (temp.timeStamp - last!.timeStamp) < 300 { // 如果不到5分钟
                temp.timeStamp = last!.timeStamp
                temp.open = last!.open // open为之前存储的值
                temp.high = max(last!.high, value)
                temp.low = min(last!.low, value)
                data[data.count - 1] = temp
                chart.animationGraphStyle = .None
            } else {
                data.append(temp)
                chart.animationGraphStyle = .Fade
            }
        }
        let json1 = "[\(temp.timeStamp),\(temp.open),\(temp.high),\(temp.low),\(temp.close)]"
//        println(json1)
        // 写历史数据
        let path = getHistory(NSDate())
        let file = NSFileHandle(forUpdatingAtPath: path)
        if file == nil {
            json = "[\(json1)]"
            NSFileManager.defaultManager().createDirectoryAtPath(path.stringByDeletingLastPathComponent, withIntermediateDirectories: false, attributes: nil, error: nil) // 创建目录
            NSFileManager.defaultManager().createFileAtPath(path, contents: json.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil) // 创建文件
            data.append(temp) // 重要，不然新安装last会一直为nil
        } else {
            if (temp.timeStamp - last!.timeStamp) < 300 { // 不到5分钟，替换
                // TODO: 待测试，这个last可能已被改变
                let range = json.rangeOfString("[", options: .BackwardsSearch)
                json = "\(json.substringToIndex(range!.startIndex))\(json1)]"
            } else { // 超过5分钟，新增
                json = "\(json.substringToIndex(advance(json.startIndex, countElements(json) - 1))),\(json1)]"
            }
//            println(json)
            json.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        }
        setChartSize()
        chart.reloadGraph() // 重绘
        // 通知
        let defautls = NSUserDefaults.standardUserDefaults()
        if value <= Util.lowTemperature() { // 温度过低
            view.backgroundColor = UIColor.colorWithHex(IDO_PURPLE)
            if Util.isLowTNotice() {
                sendNotifition("温度过低", temperature: value)
            }
        } else if value >= Util.HighTemperature() { // 温度过高
            view.backgroundColor = UIColor.colorWithHex(IDO_RED)
            if Util.isHighTNotice() {
                sendNotifition("温度过高", temperature: value)
            }
        } else {
            view.backgroundColor = UIColor.colorWithHex(IDO_GREEN)
        }
    }
    
    // MARK: - 💙 BEMSimpleLineGraphDataSource
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
    
    // MARK: - 💛 Action
    func devices(sender: AnyObject?) {
        performSegueWithIdentifier(segueId, sender: self)
    }
    
    func settings(sender: AnyObject?) {
        performSegueWithIdentifier("segue_home_settings", sender: self)
    }
    
    func history(sender: AnyObject?) {
        performSegueWithIdentifier("segue_home_history", sender: self)
    }
    
    @IBAction func reconnectPeripheral(sender: AnyObject?) {
        reconnectBtn.hidden = true
        temperatureLabel.hidden = false
        BLEManager.sharedManager().startScan()
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func setChartSize() {
        chart.frame.size = CGSizeMake(scrollView.frame.width * CGFloat(data.count) / 244 * 2, chart.frame.height)
        scrollView.contentSize.width = max(chart.frame.width, scrollView.frame.width)
    }
    
    func getHistory(date: NSDate) -> String {
        let format = NSDateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        format.timeZone = NSTimeZone(name: "UTC")
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        return paths[0].stringByAppendingPathComponent("temperature/\(format.stringFromDate(date)).json")
    }
    
    func getTimeStamp(date: NSDate, minute: Int) -> Int {
        let calendar = NSCalendar.autoupdatingCurrentCalendar() // TODO: 用这个日历是否总是对
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute, fromDate: date)
        components.minute = components.minute / minute * minute
//        println(calendar.dateFromComponents(components))
        return Int(calendar.dateFromComponents(components)!.timeIntervalSince1970)
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
