//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Settings: TableDetail {
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData() // TODO: 临时，处理改变单位后回来的滚动条问题
    }
    
    override func viewWillDisappear(animated: Bool) {
        initSettings() // 在退出Settings界面的时候统一处理，防止遗漏
        super.viewWillDisappear(animated)
    }
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        items = [
            [R.Pref.NotificationLow.rawValue, R.Pref.NotificationHigh.rawValue],
            [R.Pref.LowTemperature.rawValue, R.Pref.HighTemperature.rawValue],
            [R.Pref.TemperatureUnit.rawValue],
            [R.Pref.Review.rawValue]
        ]
        title = LocalizedString("settings")
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "cancel")
    }
    
    override func getItemView<T : NSObject, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, cell: C) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        switch indexPath.section {
        case 0:
            cell.imageView?.image = UIImage.imageWithColor(indexPath.row == 0 ? UIColor.colorWithHex(R.Color.iDoPurple.rawValue) : UIColor.colorWithHex(R.Color.iDoRed.rawValue), size: CGSizeMake(22, 22))
            cell.textLabel?.text = LocalizedString(item)
            let switchView = UISwitch()
            switchView.on = getBool(item)
            switchView.addTarget(self, action: indexPath.row == 0 ? "switchLowAlert:" : "switchHighAlert:", forControlEvents: .ValueChanged)
            cell.accessoryView = switchView
        case 1:
            let slider = UISlider(frame: CGRectMake(0, 0, 160, 20))
            slider.minimumValue = indexPath.row == 0 ? 26 : 36
            slider.maximumValue = indexPath.row == 0 ? 36 : 46
            slider.value = Float(getDouble(item))
            slider.tag = indexPath.row
            slider.addTarget(self, action: "changeTemperature:", forControlEvents: .ValueChanged)
            cell.accessoryView = slider
            let label = LocalizedString((indexPath.row == 0 ? "low" : "high"))
            cell.textLabel?.text = "\(label) \(transformTemperature(round(Double(slider.value) / 0.1) * 0.1, temperatureUnit))"
        case 2:
            cell.textLabel?.text = LocalizedString(item)
            cell.detailTextLabel?.text = getPref(item)
            cell.accessoryType = .DisclosureIndicator
            cell.selectionStyle = .Default
        case 3:
            cell.textLabel?.text = LocalizedString(item)
            cell.accessoryType = .DisclosureIndicator
        default: break
        }
        return cell
    }
    
    // MARK: - 💙 UITableViewDataSource
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
        if indexPath.section == 2 {
            performSegueWithIdentifier("segue.settings-temperature_unit_detail", sender: self)
        } else if indexPath.section == 3 {
            openAppReviews(APP_ID)
        }
    }
    
    // MARK: - 💛 Action
    func switchLowAlert(sender: UISwitch) {
        let value = sender.on
        putBool(R.Pref.NotificationLow.rawValue, value)
    }
    
    func switchHighAlert(sender: UISwitch) {
        let value = sender.on
        putBool(R.Pref.NotificationHigh.rawValue, value)
    }
    
    func changeTemperature(sender: UISlider) {
        let value = round(Double(sender.value) / 0.1) * 0.1
        putDouble(sender.tag == 0 ? R.Pref.LowTemperature.rawValue : R.Pref.HighTemperature.rawValue, value)
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: sender.tag, inSection: 1))?.textLabel?.text = (sender.tag == 0 ? LocalizedString("low") : LocalizedString("high")) + " \(transformTemperature(value, temperatureUnit))"
    }
}
