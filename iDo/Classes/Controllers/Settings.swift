//
//  Copyright (c) 2014年 NY. All rights reserved.
//

let PREF_LOW_TEMPERATURE = "low_temperature"
let PREF_HIGH_TEMPERATURE = "high_temperature"
let PREF_NOTIFICATION_LOW = "notification_low"
let PREF_NOTIFICATION_HIGH = "notification_high"

class Settings: UITableViewController {
    
    var cellId = "list_cell"
    
    // MARK: - 💖 生命周期 (Lifecyle)
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedString("settings")
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellId)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "back:")
    }
    
    // MARK: - 💙 UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 2
        default:
            return 1
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return LocalizedString("notifications")
        case 1:
            return LocalizedString("temperature")
        default:
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(cellId) as UITableViewCell
        cell.selectionStyle = .None
        switch indexPath.section {
        case 0:
            cell.imageView?.image = UIImage.imageWithColor(indexPath.row == 0 ? UIColor.colorWithHex(IDO_PURPLE) : UIColor.colorWithHex(IDO_RED), size: CGSizeMake(29, 29))
            UIImageView.roundedView(cell.imageView, cornerRadius: 14.5)
            cell.textLabel?.text = indexPath.row == 0 ? LocalizedString("low temperature alarm") : LocalizedString("high temperature alarm")
            let switchView = UISwitch(frame: CGRectZero)
            switchView.on = indexPath.row == 0 ? Settings.isLowTNotice() : Settings.isHighTNotice()
            switchView.addTarget(self, action: indexPath.row == 0 ? "switchLowTNotice:" : "switchHighTNotice:", forControlEvents: .ValueChanged)
            cell.accessoryView = switchView
        case 1:
            cell.imageView?.image = UIImage(named: "ic_settings_temperature")?.imageWithRenderingMode(.AlwaysTemplate)
            cell.imageView?.tintColor = indexPath.row == 0 ? UIColor.colorWithHex(IDO_PURPLE) : UIColor.colorWithHex(IDO_RED)
            let slider = UISlider(frame: CGRectMake(0, 0, 150, 20))
            slider.minimumValue = indexPath.row == 0 ? 26 : 36
            slider.maximumValue = indexPath.row == 0 ? 36 : 47
            slider.value = indexPath.row == 0 ? Settings.lowTemperature() : Settings.HighTemperature()
            slider.tag = indexPath.row
            slider.addTarget(self, action: "changeTemperature:", forControlEvents: .ValueChanged)
            cell.accessoryView = slider
            let label = indexPath.row == 0 ? LocalizedString("low") : LocalizedString("high")
            cell.textLabel?.text = "\(label) \(slider.value)"
        case 2:
            cell.textLabel?.text = "℃ / ℉"
            let switchView = UISwitch(frame: CGRectZero)
            switchView.on = false
            cell.accessoryView = switchView
        default:
            cell.textLabel?.text = LocalizedString("unknown")
        }
        return cell
    }
    
    // MARK: - 💛 Action
    func back(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func switchLowTNotice(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: PREF_NOTIFICATION_LOW)
    }
    
    func switchHighTNotice(sender: UISwitch) {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: PREF_NOTIFICATION_HIGH)
    }
    
    func changeTemperature(sender: UISlider) {
        let temperature = roundf(sender.value / 0.1) * 0.1
        sender.tag == 0 ? Settings.setLowTemperature(temperature) : Settings.setHighTemperature(temperature)        
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: sender.tag, inSection: 1))?.textLabel?.text = (sender.tag == 0 ? LocalizedString("low") : LocalizedString("high")) + " \(temperature)"
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    class func lowTemperature() -> Float {
        if NSUserDefaults.standardUserDefaults().objectForKey(PREF_LOW_TEMPERATURE) == nil {
            setLowTemperature(36.0)
        }
        return NSUserDefaults.standardUserDefaults().floatForKey(PREF_LOW_TEMPERATURE)
    }
    
    class func setLowTemperature(value: Float) {
        NSUserDefaults.standardUserDefaults().setFloat(value, forKey: PREF_LOW_TEMPERATURE)
    }
    
    class func HighTemperature() -> Float {
        if NSUserDefaults.standardUserDefaults().objectForKey(PREF_HIGH_TEMPERATURE) == nil {
            setHighTemperature(38.0)
        }
        return NSUserDefaults.standardUserDefaults().floatForKey(PREF_HIGH_TEMPERATURE)
    }
    
    class func setHighTemperature(value: Float) {
        NSUserDefaults.standardUserDefaults().setFloat(value, forKey: PREF_HIGH_TEMPERATURE)
    }
    
    // 低温报警
    class func isLowTNotice() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(PREF_NOTIFICATION_LOW)
    }
    
    // 高温报警
    class func isHighTNotice() -> Bool {
        if NSUserDefaults.standardUserDefaults().objectForKey(PREF_NOTIFICATION_HIGH) == nil {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: PREF_NOTIFICATION_HIGH)
        }
        return NSUserDefaults.standardUserDefaults().boolForKey(PREF_NOTIFICATION_HIGH)
    }
}
