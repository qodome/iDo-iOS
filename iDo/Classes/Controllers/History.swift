//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import UIKit

class History: UIViewController, ScrolledChartDelegate, ScrolledChartDataSource {
    
    let IDOBLUECOLOR = UIColor.colorWithHex(0x2897C3)
    var sectionsCount = 24
    var pointNumberInsection = 12
    var data: [Int : CGFloat] = Dictionary()
    var pageCount = 4
    var titleStringArrForXAXis:[String] = [] //横坐标的string
    var titleStringArrForYMaxPoint = "max"
    var datepicker: DIDatepicker!
    var frontDate: NSDate!
    var numberOfDayFordatePicker = 31
    var currentSelectedDateString: NSString = DateUtil.stringFromDate(NSDate(), WithFormat: "yyyy-MM-dd")
    @IBOutlet weak var calenderBtn: UIBarButtonItem!
    @IBOutlet weak var numberTaped: UILabel! //显示当前温度的label
    @IBOutlet weak var dateShow: UILabel!
    @IBOutlet var scrolledChart: ScrolledChart?
    
    //MARK: - lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = IDOBLUECOLOR
        calenderBtn.title = LocalizedString("calender")
        numberTaped.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        numberTaped.text = ""
        dateShow.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        dateShow.text = ""
        var date:NSDate = NSDate()
        var calendar:NSCalendar = NSCalendar.currentCalendar()
        var components:NSDateComponents = calendar.components(
            NSCalendarUnit.CalendarUnitHour | NSCalendarUnit.CalendarUnitMinute | NSCalendarUnit.CalendarUnitSecond, fromDate: date)
        components.hour = -24 * (numberOfDayFordatePicker - 1)
        frontDate = calendar.dateByAddingComponents(components, toDate: date, options: NSCalendarOptions.MatchLast) // 还要改时区
        println("date - \(date)  yesterday - \(frontDate)")
        initDatePicker()
    }
    
    //MARK: - ScrolledChartDataSource
    func numberOfSectionsInScrolledChart(scrolledChart: LineChart) ->Int {
        return sectionsCount
    }
    
    func allNumberOfPointsInSection(scrolledChart: LineChart) ->Int {
        return pointNumberInsection
    }
    
    func numberOfPointsInScrolledChart(scrolledChart: LineChart) ->Int {
        return data.values.array.count
    }
    
    func scrolledChart(scrolledChart: LineChart, keyForItemAtPointNumber pointNumber: Int) ->Int {
        var sortKeys = (data.keys).array.sorted({$0 < $1})
        return sortKeys[pointNumber]
    }
    
    func scrolledChart(scrolledChart: LineChart, valueForItemAtKey key: Int) ->CGFloat {
        return data[key]!
    }
    
    func maxDataInScrolledChart(scrolledChart: LineChart) ->CGFloat {
        return maxValueForLineChart(data)
    }
    
    func scrolledChart(scrolledChart: LineChart, titleInXAXisPointLabelInSection section: Int) ->String {
        return titleStringArrForXAXis[section]
    }
    
    // MARK: - ScrolledChartDelegate
    func scrolledChart(scrolledChart: LineChart, didClickItemAtPointNumber pointNumber: Int) {
        //println("data - \(data.description)")
        println("didClickItemAtIndexPath")
        numberTaped.text = NSString(format: "%.2f°C", Float(data[pointNumber]!))
    }
    
    // MARK: - Custom Method
    @IBAction func calenderBtnSelected(sender: AnyObject) {
        if datepicker != nil {
            datepicker.removeFromSuperview()
            datepicker = nil
        }
        else {
            initDatePicker()
        }
    }
    
    func initDatePicker() {
        println("a")
        datepicker = DIDatepicker(frame: CGRectMake(0, 60, view.frame.width, 50))
        view.addSubview(datepicker)
        datepicker.fillDatesFromDate(frontDate, numberOfDays: (numberOfDayFordatePicker - 1))
        datepicker.selectDateAtIndex(UInt(numberOfDayFordatePicker - 2) )
        datepicker.addTarget(self, action: "updateSelectedDate", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    func updateSelectedDate() {
        var dateStr = DateUtil.stringFromDate((datepicker.selectedDate)!, WithFormat: "yyyy-MM-dd")
        datepicker.removeFromSuperview()
        datepicker = nil
        // 根据date 从数据中取出温度记录 就是eLineChart的数据源
        if dateStr == currentSelectedDateString {
            return
        }
        if generateChartDataWithDateString(dateStr) {
            // 由数据源改变 eLineChart的值
            initSubViewToView()
            numberTaped.text = " "
            dateShow.text = dateStr
            currentSelectedDateString = dateStr
        } else {
            var title = LocalizedString("Prompt")
            var message = LocalizedString("Don't have any data on the day !")
            var cancelBtnTittle = LocalizedString("Done")
            UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: cancelBtnTittle).show()
        }
    }
    
    /** generate data */
    func generateChartDataWithDateString(dateStr: String) ->Bool {
        var tempArray: NSMutableArray = OliveDBDao.queryHistoryWithDay(DateUtil.dateFromString(dateStr, withFormat: "yyyy-MM-dd"))
        if tempArray.count == 0 {
            //无数据
            println("无数据")
            return false
        }
        data = ChartDataConverter().convertDataForHistory(tempArray).0
        titleStringArrForXAXis = ChartDataConverter().convertDataForHistory(tempArray).1
        return true
    }
    
    func initSubViewToView() {
        var currentGraphChartFrame: CGRect!
        if scrolledChart != nil {
            currentGraphChartFrame = scrolledChart?.frame
            scrolledChart?.removeFromSuperview()
        }
        titleStringArrForYMaxPoint = NSString(format: "%.2f", Float(maxValueForLineChart(data)))
        scrolledChart = ScrolledChart(frame: currentGraphChartFrame, pageCount: Float(pageCount), titleInYAXisMax: titleStringArrForYMaxPoint)
        // add scrollChart
        scrolledChart?.backgroundColor = UIColor.clearColor()
        scrolledChart?.lineChart.dataSource = self
        scrolledChart?.lineChart.delegate = self
        view.addSubview(scrolledChart!)
        scrolledChart?.hidden = false
    }
    
    func maxValueForLineChart(data: [Int : CGFloat])-> CGFloat {
        if data.isEmpty  {
            fatalError("data为空")
        }
        var sortValues = (data.values).array.sorted({$0 > $1})
        return sortValues[0]
    }
}
