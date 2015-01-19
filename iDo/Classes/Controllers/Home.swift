//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Home: UIViewController, BLEManagerDelegate, BLEManagerDataSource, UIAlertViewDelegate {
    // MARK: - 🍀 变量
    let segueId = "segue.home-device_list"
    var data: [Temperature] = []
    var numberView: NumberView!
    
    var json = "" // 历史数据json
    
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
        // 温度值
        let width = SCREEN_WIDTH - 30
        numberView = NumberView(frame: CGRectMake((SCREEN_WIDTH - width) / 2, (SCREEN_HEIGHT - width) / 2, width, width))
        numberView.textColor = UIColor.whiteColor()
        numberView.layer.cornerRadius = width / 2
        view.addSubview(numberView)
        // 蓝牙
        BLEManager.sharedManager().dataSource = self
        // 取当天的历史数据
        json = History.getJson(NSDate())
        data = History.getData(NSDate())
        //        value = Double(arc4random_uniform(150)) / 100 + 37 // 生成假数据
        //        onUpdateTemperature(15.15, nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarStyle(.Transparent)
        BLEManager.sharedManager().delegate = self
        if data.last?.close != nil { // 从Settings回来重算背景色
            updateUI(data.last!.close!)
        }
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
            //            view.backgroundColor = UIColor.whiteColor()
            title = ("bluetooth closed")
        case .Idle:
            view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
        case .Scan:
            title = LocalizedString("scan") // Scan不要加颜色，有广播信息的时候会乱
        case .Discovered:
            title = LocalizedString("discovered \(BLEManager.sharedManager().reconnectCount)")
        case .Connecting:
            title = LocalizedString("connecting")
        case .Connected:
            title = LocalizedString("connected")
        case .Disconnected:
            view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
            if BLEManager.sharedManager().defaultDevice() == nil {
                title = LocalizedString("no_device")
            } else {
                title = LocalizedString("reconnecting")
            }
        case .Fail:
            title = "Fail"
            view.backgroundColor = UIColor.blackColor()
        case .ServiceDiscovered:
            title = LocalizedString("service discovered")
        default:
            title = "Unknown State: \(state.rawValue)"
        }
    }
    
    // MARK: - 🐤 BLEManagerDataSource
    func onUpdateTemperature(var value: Double, peripheral: CBPeripheral?) {
        value = round(value / 0.1) * 0.1 // 四舍五入保留一位小数
        updateUI(value)
        title = peripheral?.name
        // 初始化一个温度对象，当前时间最接近的5分钟频率
        let date = NSDate()
        let temp = Temperature(timeStamp: History.getTimeStamp(date, minute: 5), value: value)
        // 比对历史数据
        let path = History.getHistory(date) // 当前应该写入的文件路径
        var json1 = ""
        var last = data.last
        if last != nil {
            if path != History.getHistory(NSDate(timeIntervalSince1970: Double(last!.timeStamp))) {
                data.removeAll(keepCapacity: true)
                json = ""
                last = nil
            } else { // 没跨天
                let cycle = (temp.timeStamp - last!.timeStamp) / 300
                if cycle < 1 { // 如果不到5分钟，该情况下温度值不可能为null
                    temp.timeStamp = last!.timeStamp
                    temp.open = last!.open // open为之前存储的值
                    temp.high = max(last!.high!, value)
                    temp.low = min(last!.low!, value)
                    data[data.count - 1] = temp
                } else {
                    for i in 1..<cycle { // 补空
                        let t = last!.timeStamp + 300 * i
                        data.append(Temperature(timeStamp: t))
                        json1 += getJsonData(t, nil, nil, nil, nil) + ","
                    }
                    data.append(temp)
                }
            }
        }
        json1 += getJsonData(temp.timeStamp, temp.open, temp.high, temp.low, temp.close)
        // 写历史数据
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
            json.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        }
    }
    
    func getJsonData(values: NSObject?...) -> String { // TODO: 是否用AnyObject更安全
        var json = "["
        for value in values {
            json = String(format: "\(json)%@,", value == nil ? "null" : value!)
        }
        let range = json.rangeOfString(",", options: .BackwardsSearch)
        json.replaceRange(range!, with: "]")
        //                println(json)
        return json
    }
    
    // MARK: - 💙 UIAlertViewDelegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 { // 进入设备页
            BLEManager.sharedManager().startScan() // TODO: 是否要放在这里做
            performSegueWithIdentifier(segueId, sender: self)
        }
    }
    
    // MARK: - 💛 Action
    func devices(sender: AnyObject) {
        performSegueWithIdentifier(segueId, sender: self)
    }
    
    func settings(sender: AnyObject) {
        performSegueWithIdentifier("segue.home-settings", sender: self)
    }
    
    func history(sender: AnyObject) {
        performSegueWithIdentifier("segue.home-history", sender: self)
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func updateUI(var value: Double) {
        let displayValue = transformTemperature(value, isFahrenheit)
        let symbol = isFahrenheit ? "℉" : "℃"
        numberView.setValue(displayValue)
        if value <= Settings.getTemperature(R.Pref.LowTemperature) { // 温度过低
            view.backgroundColor = UIColor.colorWithHex(IDO_PURPLE)
            if lowAlert {
//            if Settings.isLowTNotice() {
                sendNotifition("💧温度过低 \(displayValue) \(symbol)")
            }
        } else if value >= Settings.getTemperature(R.Pref.HighTemperature) { // 温度过高
            view.backgroundColor = UIColor.colorWithHex(IDO_RED)
            if highAlert {
                sendNotifition("🔥温度过高 \(displayValue) \(symbol)")
            }
        } else {
            view.backgroundColor = UIColor.colorWithHex(IDO_GREEN)
        }
    }
    
    /** 本地通知 */
    func sendNotifition(message: String) {
        if UIApplication.sharedApplication().applicationState == .Background {
            let notification = UILocalNotification()
            notification.fireDate = NSDate().dateByAddingTimeInterval(3)
            notification.alertBody = message
            notification.soundName = UILocalNotificationDefaultSoundName
            //            notification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
            notification.applicationIconBadgeNumber = 1
            UIApplication.sharedApplication().scheduleLocalNotification(notification)
        }
    }
}
