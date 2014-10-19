//
//  Copyright (c) 2014年 NY. All rights reserved.
//

protocol CalendarViewDelegate {
    func didSelectDate(dateStr:String, forDetail enty:WeekEntity)
}

class CalendarView:UIView, UITableViewDataSource, UITableViewDelegate {

    let cellIdentity: String = "calendarViewell"
    var dataSourceArr: NSMutableArray? = nil
    var mainTableView: UITableView? = nil
    var delegate: CalendarViewDelegate? = nil
    var defaultselectedDate: String? = nil

    // MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadModels()
        buildUI()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func kUIColorFromRGB(rgbValue: Int) -> UIColor {
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0xFF00) >> 8) / 255.0
        let blue = Double((rgbValue & 0xFF)) / 255.0
        let alpha = 1.0
        var color: UIColor = UIColor( red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha:CGFloat(alpha) )
        return color
    }

    // MARK: - custom method
    func loadModels() {
        dataSourceArr = NSMutableArray()
        for var i = 0; i <= 30; i++ {
            let secondsPerDay: NSTimeInterval = (NSTimeInterval)(24 * 60 * 60.0 * i)
            
            let today: NSDate = NSDate.date()
            let preDate: NSDate = today.dateByAddingTimeInterval(-secondsPerDay)
            
            let cal: NSCalendar = NSCalendar.currentCalendar()
            let comp: NSDateComponents = cal.components(NSCalendarUnit.WeekdayCalendarUnit, fromDate: preDate)
            let week: WeekType = WeekType.fromRaw(comp.weekday)!   //?
            var we: WeekEntity = WeekEntity()
            we.weekDate = stringFromDate(preDate, withFormat: "yyyy-MM-dd")
            we.weektype = week
            switch i {
            case 0:
                defaultselectedDate = we.weekDate
                we.subtitule = LocalizedString("Today")
            case 1:
                we.subtitule = LocalizedString("Yesterday")
            case 2:
                we.subtitule = LocalizedString("B yesterday")
            default:
                we.subtitule = ""
            }
            dataSourceArr?.addObject(we)
        }
    }

    func buildUI() {
        //backgroundColor = UIColor(red: 209/255.0, green: 209/255.0, blue: 209/255.0, alpha: 1.0)
        backgroundColor = UIColor.clearColor()
        //背景图片
        let bgImageView: UIImageView = UIImageView(frame: bounds)
        addSubview(bgImageView)
        //时间轴的分割线
//        var seperatorLine: UIView = UIView(frame: CGRectMake(28, 0, 1, 1000))
//        addSubview(seperatorLine)
//        seperatorLine.backgroundColor = UIColor.lightGrayColor()
        //tableView 生成和相关参数设置
        mainTableView = UITableView(frame: CGRectZero, style: UITableViewStyle.Plain)
        mainTableView?.frame = bounds
        mainTableView?.delegate = self
        mainTableView?.dataSource = self
        mainTableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        mainTableView?.separatorColor = UIColor.clearColor()
        mainTableView?.backgroundColor = UIColor.clearColor()
        mainTableView?.registerClass(WeekCell.self, forCellReuseIdentifier: cellIdentity)
        addSubview(mainTableView!)
    }

    func stringFromDate(date: NSDate, withFormat format: String) -> String {
        var dateFromatter: NSDateFormatter = NSDateFormatter()
        dateFromatter.dateFormat = format
        return dateFromatter.stringFromDate(date)
    }

    func colorForWeek(weektype:WeekType) -> UIColor {
        var color: UIColor = UIColor.grayColor()
        switch (weektype) {
        case WeekType.Monday:
            color = kUIColorFromRGB(0xFF6666)
        case WeekType.Tuesday:
            color = kUIColorFromRGB(0x6699FF)
        case WeekType.Wednesday:
            color = kUIColorFromRGB(0xCCCC99)
        case WeekType.Thursday:
            color = kUIColorFromRGB(0xCC9999)
        case WeekType.Friday:
            color = kUIColorFromRGB(0xFFCCCC)
        case WeekType.Saturday:
            color = kUIColorFromRGB(0xFF9900)
        default:
            color = UIColor.grayColor()
        
        }
        return color
    }

    func titleForWeek(weektype:WeekType) -> String {
        var title:String = String()
        switch (weektype) {
        case WeekType.Monday:
            title = "周一"
        case WeekType.Tuesday:
            title = "周二"
        case WeekType.Wednesday:
            title = "周三"
        case WeekType.Thursday:
            title = "周四"
        case WeekType.Friday:
            title = "周五"
        case WeekType.Saturday:
            title = "周六"
        case WeekType.Sunday:
            title = "周日"
        default:
            title = ""
        }
        return title
    }

    func setDefautSelectedDate(mDefautSelectedDate: String) {
        defaultselectedDate = mDefautSelectedDate
        mainTableView?.reloadData()
    }

    // MARK:- tableView delegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (dataSourceArr?.count)!
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: WeekCell = tableView.dequeueReusableCellWithIdentifier(cellIdentity, forIndexPath: indexPath) as WeekCell
        let enti: WeekEntity = dataSourceArr?.objectAtIndex(indexPath.row) as WeekEntity
        cell.weekButton.backgroundColor = colorForWeek(enti.weektype)
        cell.weekLable.text = titleForWeek(enti.weektype)
        if enti.subtitule != nil && !enti.subtitule.isEmpty {
            cell.weekDateLabel.text = "\(enti.weekDate)  \(enti.subtitule)"
        } else {
            cell.weekDateLabel.text = enti.weekDate
        }
        if enti.weekDate == defaultselectedDate {
            cell.weekDateLabel.textColor = kUIColorFromRGB(0x3399CC)
        } else {
            cell.weekDateLabel.textColor = UIColor.darkTextColor()
        }
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let enti: WeekEntity! = dataSourceArr?.objectAtIndex(indexPath.row) as WeekEntity
        defaultselectedDate = enti.weekDate
        delegate?.didSelectDate(enti.weekDate, forDetail: enti)
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }

}
