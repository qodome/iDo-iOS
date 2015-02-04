//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class History: UIViewController, JTCalendarDataSource, BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource {
    
    var data: [Temperature] = []
    var calendarMenuView: JTCalendarMenuView!
    var calendarContentView: JTCalendarContentView!
    var calendar: JTCalendar!
    var scrollView: UIScrollView!
    var chart: BEMSimpleLineGraphView!
    
    var segment: UISegmentedControl!
    var timeLabel: UILabel!
    
    var json = "" // 历史数据json
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        let color = UIColor.colorWithHex(R.Color.iDoBlue.rawValue)
        view.backgroundColor = color
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocalizedString("today"), style: .Bordered, target: self, action: "today:")
        segment = UISegmentedControl()
        segment.insertSegmentWithTitle(LocalizedString("general"), atIndex: 0, animated: false)
        segment.insertSegmentWithTitle(LocalizedString("advanced"), atIndex: 1, animated: false)
        segment.sizeToFit()
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: "change:", forControlEvents: .ValueChanged)
        navigationItem.titleView = segment
        timeLabel = UILabel(frame: CGRectMake(0, 64, view.frame.width, 32))
        timeLabel.textColor = UIColor.whiteColor()
        timeLabel.text = "04:00 AM - 07:00 AM"
        timeLabel.sizeToFit()
        timeLabel.frame.origin.x = (view.frame.width - timeLabel.frame.width) / 2
        view.addSubview(timeLabel)
        timeLabel.hidden = true
        // 日历
        calendarMenuView = JTCalendarMenuView(frame: CGRectMake(0, 64, view.frame.width, 32))
        calendarContentView = JTCalendarContentView(frame: CGRectMake(0, 96, view.frame.width, 88))
        view.addSubview(calendarMenuView)
        view.addSubview(calendarContentView)
        calendar = JTCalendar()
        calendar.calendarAppearance.isWeekMode = true
        calendar.calendarAppearance.ratioContentMenu = 1 // 显示几个月份
        calendar.calendarAppearance.menuMonthTextColor = UIColor.whiteColor()
        calendar.calendarAppearance.weekDayTextColor = UIColor.whiteColor()
        calendar.calendarAppearance.weekDayFormat = .Single // 星期格式
        calendar.calendarAppearance.dayCircleColorSelected = UIColor.whiteColor()
        calendar.calendarAppearance.dayTextColor = UIColor.whiteColor()
        calendar.calendarAppearance.dayTextColorSelected = color
        calendar.calendarAppearance.dayDotColor = UIColor.whiteColor()
        calendar.calendarAppearance.dayDotColorSelected = color
        calendar.menuMonthsView = calendarMenuView
        calendar.contentView = calendarContentView
        calendar.dataSource = self
        calendar.currentDateSelected = NSDate()
        // 图表
        chart = BEMSimpleLineGraphView(frame: CGRectMake(0, 0, view.frame.width * 2, 240))
        // ❨╯°□°❩╯︵┻━┻
        let components: [CGFloat] = [1, 1, 1, 0.8, 1, 1, 1, 0]
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
        // 滚动区域
        let touch = UIView(frame: CGRectMake(0, chart.frame.height, chart.frame.width, 44))
        touch.backgroundColor = UIColor.colorWithHex(0xFFFFFF, alpha: 0.1)
        scrollView.addSubview(touch)
        view.addSubview(scrollView)
        // 取当天的历史数据
        data = History.getData(calendar.currentDateSelected)
        setChartSize() // 要放在加载数据之后
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarStyle(.Transparent)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        calendar.reloadData()
        // TODO: 当天数据是否需要重载
    }
    
    // MARK: - 💙 JTCalendarDataSource
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool {
        return NSFileHandle(forReadingAtPath: History.getHistory(date)) != nil
    }
    
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!) {
        //        println("hahhahahhahahha")
        data.removeAll(keepCapacity: true)
        data += History.getData(date)
        setChartSize() // 要放在加载数据之后
        chart.reloadGraph()
    }
    
    // MARK: - 💙 BEMSimpleLineGraphDataSource
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView!) -> Int {
        return data.count
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView!, valueForPointAtIndex index: Int) -> CGFloat {
        let value = data[index].high
        return value != nil ? CGFloat(transformTemperature(value!, temperatureUnit)) : 0
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView!, labelOnXAxisForIndex index: Int) -> String! {
        let date = NSDate(timeIntervalSince1970: Double(data[index].timeStamp))
        let formatter = NSDateFormatter()
        var components: NSDateComponents!
        // TODO: 用这个日历是否总是对
        if segment.selectedSegmentIndex == 0 {
            formatter.dateFormat = "HH:mm" // "hh:mm a"
            components = NSCalendar.autoupdatingCurrentCalendar().components(.CalendarUnitMinute, fromDate: date)
            //        return components.minute == 0 ? format.stringFromDate(date) : ""
        } else {
            formatter.dateFormat = "yyyy-MM-dd"
            components = NSCalendar.autoupdatingCurrentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: date)
        }
        return formatter.stringFromDate(date)
    }
    
    // MARK: 💙 BEMSimpleLineGraphDelegate
    //    func popUpSuffixForlineGraph(graph: BEMSimpleLineGraphView!) -> String! {
    //        return "°"
    //    }
    
    // MARK: - 💛 Action
    func change(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            today(sender)
        case 1:
            let date = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let from = date.dateByAddingDay(-30)
            data = History.getHistoryData(formatter.stringFromDate(from), endDate: formatter.stringFromDate(date), startTime: "04:00", endTime: "07:00")
            calendarContentView.hidden = true
            calendarMenuView.hidden = true
            timeLabel.hidden = false
            chart.frame.size.width = view.frame.width - 20
            scrollView.contentSize.width = chart.frame.width
            chart.reloadGraph()
        default: break
        }
    }
    
    func today(sender: AnyObject) {
        calendarContentView.hidden = false
        calendarMenuView.hidden = false
        timeLabel.hidden = true
        let date = NSDate()
        calendar.currentDateSelected = date // 这句必须放在前面，否则同屏会不选中
        calendar.currentDate = date
        calendarDidDateSelected(calendar, date: date) // 绘图表
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func setChartSize() {
        chart.frame.size.width = scrollView.frame.width * CGFloat(data.count) / 244 * 2
        scrollView.contentSize.width = max(chart.frame.width, scrollView.frame.width)
    }
    
    class func getData(date: NSDate) -> [Temperature] {
        var data: [Temperature] = []
        var content: [AnyObject] = []
        let path = getHistory(date)
        if NSFileHandle(forReadingAtPath: path) != nil {
            let json = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
            let content = NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding)!, options: .allZeros, error: nil) as Array<AnyObject>
            for d in content {
                let temperature = Temperature(timeStamp: Int(d[0] as NSNumber))
                temperature.open = d[1].isEqual(NSNull()) ? nil : Double(d[1] as NSNumber)
                temperature.high = d[2].isEqual(NSNull()) ? nil : Double(d[2] as NSNumber)
                temperature.low = d[3].isEqual(NSNull()) ? nil : Double(d[3] as NSNumber)
                temperature.close = d[4].isEqual(NSNull()) ? nil : Double(d[4] as NSNumber)
                data.append(temperature)
            }
        }
        return data
    }
    
    class func getJson(date: NSDate) -> String {
        let path = getHistory(date)
        if NSFileHandle(forReadingAtPath: path) != nil {
            return String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
        }
        return ""
    }
    
    class func getHistory(date: NSDate) -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let timeZone = formatter.timeZone.secondsFromGMT / 3600
        let timeZoneString = timeZone >= 0 ? String(format: "+%02d", timeZone) : String(format: "%02d", timeZone)
        return PATH_DOCUMENTS.stringByAppendingPathComponent("temperature/\(formatter.stringFromDate(date))\(timeZoneString).json")
    }
    
    class func getTimeStamp(date: NSDate, minute: Int) -> Int {
        let calendar = NSCalendar.autoupdatingCurrentCalendar() // TODO: 用这个日历是否总是对
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute, fromDate: date)
        components.minute = components.minute / minute * minute
        //        println(calendar.dateFromComponents(components))
        return Int(calendar.dateFromComponents(components)!.timeIntervalSince1970)
    }
    
    // MARK: -    
    class func getHistoryData(startDate: NSString, endDate: NSString, startTime: NSString, endTime: NSString) -> [Temperature] {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var current = formatter.dateFromString(startDate)!
        let end = formatter.dateFromString(endDate)
        var dataArray: [Temperature] = []
        while true {
            let currentDay = formatter.stringFromDate(current)
            let beginTime = "\(currentDay) \(startTime):00"
            let endTime = "\(currentDay) \(endTime):00"
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let startInt = dateFormatter.dateFromString(beginTime)?.timeIntervalSince1970
            let endInt = dateFormatter.dateFromString(endTime)?.timeIntervalSince1970
            if current.timeIntervalSince1970 > end!.timeIntervalSince1970 {
                break
            } else {
                if NSFileHandle(forUpdatingAtPath: getHistory(current)) == nil {
                    dataArray.append(Temperature(timeStamp: Int(startInt!)))
                } else {
                    let data = getData(current)
                    var temperature = Temperature(timeStamp: Int(current.timeIntervalSince1970))
                    for item in data {
                        if item.timeStamp >= Int(startInt!) && item.timeStamp <= Int(endInt!) {
                            if temperature.open == nil {
                                temperature = item
                            }
                            if item.high > temperature.high {
                                temperature.high = item.high
                            } else if item.low != nil && item.low < temperature.low {
                                temperature.low = item.low
                            }
                            temperature.close = item.close
                        }
                    }
                    dataArray.append(temperature)
                }
            }
            current = current.dateByAddingDay(1)
        }
        return dataArray
    }
}
