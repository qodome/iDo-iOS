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
    
    var json = "" // 历史数据json
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: LocalizedString("today"), style: .Bordered, target: self, action: "today:")
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
        calendar.calendarAppearance.dayTextColorSelected = UIColor.colorWithHex(IDO_BLUE)
        calendar.calendarAppearance.dayDotColor = UIColor.whiteColor()
        calendar.calendarAppearance.dayDotColorSelected = UIColor.colorWithHex(IDO_BLUE)
        calendar.menuMonthsView = calendarMenuView
        calendar.contentView = calendarContentView
        calendar.dataSource = self
        calendar.currentDateSelected = NSDate()
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
        data = History.getData(calendar.currentDateSelected)
        setChartSize() // 要放在加载数据之后
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        calendar.reloadData()
    }
    
    // MARK: - 💙 JTCalendarDataSource
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool {
        let path = History.getHistory(date)
        let file = NSFileHandle(forUpdatingAtPath: path)
        return file != nil // TODO 待优化
    }
    
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!) {
        println("hahhahahhahahha")
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
        return value == nil ? 0 : CGFloat(value!)
    }
    
    // MARK: - 💛 Action
    func today(sender: AnyObject) {
        let date = NSDate()
        calendar.currentDateSelected = date // 这句必须放在前面，否则同屏会不选中
        calendar.currentDate = date
        calendarDidDateSelected(calendar, date: date) // 绘图表
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    func setChartSize() {
        chart.frame.size = CGSizeMake(scrollView.frame.width * CGFloat(data.count) / 244 * 2, chart.frame.height)
        scrollView.contentSize.width = max(chart.frame.width, scrollView.frame.width)
    }
    
    class func getData(date: NSDate) -> [Temperature] {
        var data: [Temperature] = []
        let path = getHistory(date)
        let file = NSFileHandle(forUpdatingAtPath: path)
        var content: NSArray = []
        if file != nil {
            let json = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
            let content = NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding)!, options: .allZeros, error: nil) as NSArray
            for d in content {
                let temperature = Temperature(timeStamp: Int(d[0] as NSNumber))
                temperature.open = d[1].isEqual(NSNull()) ? nil : Float(d[1] as NSNumber)
                temperature.high = d[2].isEqual(NSNull()) ? nil : Float(d[2] as NSNumber)
                temperature.low = d[3].isEqual(NSNull()) ? nil : Float(d[3] as NSNumber)
                temperature.close = d[4].isEqual(NSNull()) ? nil : Float(d[4] as NSNumber)
                data.append(temperature)
            }
        }
        return data
    }
    
    class func getJson(date: NSDate) -> String {
        let path = getHistory(date)
        let file = NSFileHandle(forReadingAtPath: path)
        if file != nil {
            return NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
        }
        return ""
    }
    
    class func getHistory(date: NSDate) -> String {
        let format = NSDateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        format.timeZone = NSTimeZone(name: "UTC")
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        return paths[0].stringByAppendingPathComponent("temperature/\(format.stringFromDate(date)).json")
    }
    
    class func getTimeStamp(date: NSDate, minute: Int) -> Int {
        let calendar = NSCalendar.autoupdatingCurrentCalendar() // TODO: 用这个日历是否总是对
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute, fromDate: date)
        components.minute = components.minute / minute * minute
        //        println(calendar.dateFromComponents(components))
        return Int(calendar.dateFromComponents(components)!.timeIntervalSince1970)
    }
}
