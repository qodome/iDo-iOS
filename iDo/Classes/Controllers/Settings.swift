//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Settings: TableDetail {
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        title = LocalizedString("settings")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "cancel")
    }
    
    override func getItemView<T : NSObject, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, cell: C) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            cell.imageView?.image = UIImage.imageWithColor(indexPath.row == 0 ? UIColor.colorWithHex(R.Color.iDoPurple.rawValue) : UIColor.colorWithHex(R.Color.iDoRed.rawValue), size: CGSizeMake(22, 22))
            cell.textLabel?.text = indexPath.row == 0 ? LocalizedString("low temperature alarm") : LocalizedString("high temperature alarm")
            let switchView = UISwitch()
            switchView.on = indexPath.row == 0 ? Settings.isLowTNotice() : Settings.isHighTNotice()
            switchView.addTarget(self, action: indexPath.row == 0 ? "switchLowAlert:" : "switchHighAlert:", forControlEvents: .ValueChanged)
            cell.accessoryView = switchView
        case 1:
            let slider = UISlider(frame: CGRectMake(0, 0, 160, 20))
            slider.minimumValue = indexPath.row == 0 ? 26 : 36
            slider.maximumValue = indexPath.row == 0 ? 36 : 46
            slider.value = Float(Settings.getTemperature(indexPath.row == 0 ? R.Pref.LowTemperature : R.Pref.HighTemperature))
            slider.tag = indexPath.row
            slider.addTarget(self, action: "changeTemperature:", forControlEvents: .ValueChanged)
            cell.accessoryView = slider
            let label = indexPath.row == 0 ? LocalizedString("low") : LocalizedString("high")
            cell.textLabel?.text = "\(label) \(transformTemperature(round(Double(slider.value) / 0.1) * 0.1, isFahrenheit))"
        case 2:
            cell.textLabel?.text = "℃ / ℉"
            let switchView = UISwitch()
            switchView.on = Settings.isFahrenheit()
            switchView.addTarget(self, action: "switchFahrenheit:", forControlEvents: .ValueChanged)
            cell.accessoryView = switchView
        case 3:
            cell.textLabel?.text = LocalizedString("review")
            cell.accessoryType = .DisclosureIndicator
        default: break
        }
        return cell
    }
    
    // MARK: - 💙 UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1:
            return 2
        default:
            return 1
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return LocalizedString("notifications")
        case 1:
            return LocalizedString("temperature")
        default:
            return nil
        }
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == tableView.numberOfSections() - 1 {
            let bundle = NSBundle.mainBundle()
            let name = bundle.objectForInfoDictionaryKey("CFBundleDisplayName") as String
            let version = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as String
            let build = bundle.objectForInfoDictionaryKey("CFBundleVersion") as String
            return "\(name) \(version) (\(build))"
        }
        return nil
    }
    
    // MARK: 💙 UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 3 {
            openAppReviews(APP_ID)
        }
    }
    
    // MARK: - 💛 Action
    func switchLowAlert(sender: UISwitch) {
        let value = sender.on
        NSUserDefaults.standardUserDefaults().setBool(value, forKey: R.Pref.NotificationLow.rawValue)
        lowAlert = value
    }
    
    func switchHighAlert(sender: UISwitch) {
        let value = sender.on
        NSUserDefaults.standardUserDefaults().setBool(value, forKey: R.Pref.NotificationHigh.rawValue)
        highAlert = value
    }
    
    func switchFahrenheit(sender: UISwitch) {
        let value = sender.on
        NSUserDefaults.standardUserDefaults().setBool(value, forKey: R.Pref.Fahrenheit.rawValue)
        isFahrenheit = value
        tableView.reloadData()
    }
    
    func changeTemperature(sender: UISlider) {
        let temperature = round(Double(sender.value) / 0.1) * 0.1
        Settings.setTemperature(temperature, pref: sender.tag == 0 ? R.Pref.LowTemperature : R.Pref.HighTemperature)
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: sender.tag, inSection: 1))?.textLabel?.text = (sender.tag == 0 ? LocalizedString("low") : LocalizedString("high")) + " \(transformTemperature(temperature, isFahrenheit))"
    }
    
    // MARK: - 💛 自定义方法 (Custom Method)
    class func getTemperature(pref: R.Pref) -> Double {
        if NSUserDefaults.standardUserDefaults().objectForKey(pref.rawValue) == nil {
            setTemperature(pref == R.Pref.LowTemperature ? 35 : 37, pref: pref)
        }
        return NSUserDefaults.standardUserDefaults().doubleForKey(pref.rawValue)
    }
        
    class func setTemperature(value: Double, pref: R.Pref) {
        NSUserDefaults.standardUserDefaults().setDouble(value, forKey: pref.rawValue)
    }
    
    class func isFahrenheit() -> Bool { // 摄氏/华氏
        return NSUserDefaults.standardUserDefaults().boolForKey(R.Pref.Fahrenheit.rawValue)
    }
    
    class func isLowTNotice() -> Bool { // 低温报警
        return NSUserDefaults.standardUserDefaults().boolForKey(R.Pref.NotificationLow.rawValue)
    }
    
    class func isHighTNotice() -> Bool { // 高温报警
        if NSUserDefaults.standardUserDefaults().objectForKey(R.Pref.NotificationHigh.rawValue) == nil {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: R.Pref.NotificationHigh.rawValue)
        }
        return NSUserDefaults.standardUserDefaults().boolForKey(R.Pref.NotificationHigh.rawValue)
    }
}
