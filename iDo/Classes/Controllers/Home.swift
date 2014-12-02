//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Home: UIViewController, BLEManagerDelegate, BLEManagerDataSource, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource, UIAlertViewDelegate {
    // MARK: - 🍀 变量
    let segueId = "segue_home_device_list"
    var data: [Temperature] = []
    var scrollView: UIScrollView!
    var chart: BEMSimpleLineGraphView!
    
    var json = "" // 历史数据json
    
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
        // 蓝牙
        BLEManager.sharedManager().delegate = self
        BLEManager.sharedManager().dataSource = self
        // 图表
        chart = BEMSimpleLineGraphView(frame: CGRectMake(0, 0, view.frame.width * 2, 240))
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
        chart.delegate = self
        chart.dataSource = self
        // ScrollView
        scrollView = UIScrollView(frame: CGRectMake(0, 200, view.frame.width, chart.frame.height + 44))
        scrollView.contentSize = CGSizeMake(chart.frame.width, scrollView.frame.height)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.addSubview(chart)
        view.addSubview(scrollView)
        // 取当天的历史数据
        json = History.getJson(NSDate())
        data = History.getData(NSDate())
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
            UIAlertView(title: "",
                message: LocalizedString("choose_device"),
                delegate: self,
                cancelButtonTitle: LocalizedString("cancel"),
                otherButtonTitles: LocalizedString("ok")).show()
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
    func onUpdateTemperature(var value: Float) {
//        value = Float(arc4random_uniform(150)) / 100 + 37 // 生成假数据
        value = roundf(value / 0.01) * 0.01 // 保留两位小数
        let date = NSDate()
        temperatureLabel.text = NSString(format: "%.2f°", value)
        // 初始化一个温度对象，当前时间最接近的5分钟频率
        let temp = Temperature(timeStamp: History.getTimeStamp(date, minute: 5), value: value)
        // 比对历史数据
        var json1 = ""
        let last = data.last
        if last != nil {
            let cycle = (temp.timeStamp - last!.timeStamp) / 300
            if cycle < 1 { // 如果不到5分钟，该情况下温度值不可能为null
                temp.timeStamp = last!.timeStamp
                temp.open = last!.open // open为之前存储的值
                temp.high = max(last!.high!, value)
                temp.low = min(last!.low!, value)
                data[data.count - 1] = temp
                chart.animationGraphStyle = .None
            } else {
                for i in 1..<cycle { // 补空
                    let t = last!.timeStamp + 300 * i
                    data.append(Temperature(timeStamp: t))
                    json1 += getJsonData(t, nil, nil, nil, nil) + ","
                }
                data.append(temp)
                chart.animationGraphStyle = .Fade
            }
        }
        json1 += getJsonData(temp.timeStamp, temp.open, temp.high, temp.low, temp.close)
        // 写历史数据
        let path = History.getHistory(date)
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
        if value <= Settings.lowTemperature() { // 温度过低
            view.backgroundColor = UIColor.colorWithHex(IDO_PURPLE)
            if Settings.isLowTNotice() {
                sendNotifition("温度过低", temperature: value)
            }
        } else if value >= Settings.HighTemperature() { // 温度过高
            view.backgroundColor = UIColor.colorWithHex(IDO_RED)
            if Settings.isHighTNotice() {
                sendNotifition("温度过高", temperature: value)
            }
        } else {
            view.backgroundColor = UIColor.colorWithHex(IDO_GREEN)
        }
    }
    
    func getJsonData(values: NSObject?...) -> String { // TODO: 是否用AnyObject更安全
        var json = "["
        for value in values {
            json = NSString(format: "\(json)%@,", value == nil ? "null" : value!)
        }
        let range = json.rangeOfString(",", options: .BackwardsSearch)
        json.replaceRange(range!, with: "]")
        println(json)
        return json
    }
    
    // MARK: - 💙 BEMSimpleLineGraphDataSource
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView!) -> Int {
        return data.count
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView!, valueForPointAtIndex index: Int) -> CGFloat {
        let value = data[index].high
        return value == nil ? 0 : CGFloat(value!)
    }
    
    // MARK: - 💙 UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 { // 进入设备页
            BLEManager.sharedManager().startScan()
            performSegueWithIdentifier(segueId, sender: self)
        }
    }
    
    // MARK: - 💛 Action
    func devices(sender: AnyObject) {
        performSegueWithIdentifier(segueId, sender: self)
    }
    
    func settings(sender: AnyObject) {
        performSegueWithIdentifier("segue_home_settings", sender: self)
    }
    
    func history(sender: AnyObject) {
        performSegueWithIdentifier("segue_home_history", sender: self)
    }
    
    @IBAction func reconnectPeripheral(sender: AnyObject) {
        reconnectBtn.hidden = true
        temperatureLabel.hidden = false
        BLEManager.sharedManager().startScan()
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func setChartSize() {
        chart.frame.size = CGSizeMake(scrollView.frame.width * CGFloat(data.count) / 244 * 2, chart.frame.height)
        scrollView.contentSize.width = max(chart.frame.width, scrollView.frame.width)
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
