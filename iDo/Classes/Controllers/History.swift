//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class History: UIViewController, JTCalendarDataSource {
    
    var calendarMenuView: JTCalendarMenuView!
    var calendarContentView: JTCalendarContentView!
    var calendar: JTCalendar!
    
    @IBOutlet weak var calenderBtn: UIBarButtonItem!
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
        calenderBtn.title = LocalizedString("today")
        
        calendarMenuView = JTCalendarMenuView(frame: CGRectMake(0, 64, view.frame.width, 32))
        calendarContentView = JTCalendarContentView(frame: CGRectMake(0, 96, view.frame.width, 88))
        view.addSubview(calendarMenuView)
        view.addSubview(calendarContentView)
        calendar = JTCalendar()
        calendar.calendarAppearance.isWeekMode = true
        calendar.calendarAppearance.ratioContentMenu = 1 // 显示月份
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
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        calendar.reloadData()
    }
    
    // MARK: - 💙 JTCalendarDataSource
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool {
        return true // TODO 返回是否有历史记录
    }
    
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!) {
        println("hahhahahhahahha")
    }
    
    // MARK: 💛 自定义方法 (Custom Method)
    @IBAction func calenderBtnSelected(sender: AnyObject) {
        calendar.currentDate = NSDate()
//        calendar.currentDateSelected = NSDate()
    }
}
