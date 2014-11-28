//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class History: UIViewController {
    
    var datepicker: DIDatepicker!
    var frontDate: NSDate!
    var numberOfDayFordatePicker = 31
    var currentSelectedDateString: NSString!
    @IBOutlet weak var calenderBtn: UIBarButtonItem!
    @IBOutlet weak var dateShow: UILabel!
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.colorWithHex(IDO_BLUE)
        calenderBtn.title = LocalizedString("calender")
        dateShow.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        dateShow.text = ""
        var date:NSDate = NSDate()
        var calendar:NSCalendar = NSCalendar.currentCalendar()
        var components: NSDateComponents = calendar.components(
            NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute | NSCalendarUnit.CalendarUnitSecond, fromDate: date)
        components.hour = -24 * (numberOfDayFordatePicker - 1)
        frontDate = calendar.dateByAddingComponents(components, toDate: date, options: NSCalendarOptions.MatchLast) // 还要改时区
        datepicker = DIDatepicker(frame: CGRectMake(0, 60, view.frame.width, 50))
        view.addSubview(datepicker)
        datepicker.fillDatesFromDate(frontDate, numberOfDays: (numberOfDayFordatePicker - 1))
        datepicker.selectDateAtIndex(UInt(numberOfDayFordatePicker - 2) )
        datepicker.addTarget(self, action: "updateSelectedDate", forControlEvents: UIControlEvents.ValueChanged)
        
        currentSelectedDateString = stringFromDate(NSDate(), WithFormat: "yyyy-MM-dd")

    }
    
    // MARK: - Custom Method
    @IBAction func calenderBtnSelected(sender: AnyObject) {
        initDatePicker()
    }
    
    func initDatePicker() {
        datepicker = DIDatepicker(frame: CGRectMake(0, 60, view.frame.width, 50))
        view.addSubview(datepicker)
        datepicker.fillDatesFromDate(frontDate, numberOfDays: (numberOfDayFordatePicker - 1))
        datepicker.selectDateAtIndex(UInt(numberOfDayFordatePicker - 2) )
        datepicker.addTarget(self, action: "updateSelectedDate", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    func updateSelectedDate() {
        var dateStr = stringFromDate((datepicker.selectedDate)!, WithFormat: "yyyy-MM-dd")
        // 根据date 从数据中取出温度记录 就是eLineChart的数据源
        if dateStr == currentSelectedDateString {
            return
        }
        println("hahhahahhahahha")
        dateShow.text = dateStr
        currentSelectedDateString = dateStr
    }
    
    // MARK: -
    func stringFromDate(date: NSDate, WithFormat format: NSString) -> NSString {
        var dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.stringFromDate(date)
    }
}
