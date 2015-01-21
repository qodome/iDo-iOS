//
//  Copyright (c) 2015年 NY. All rights reserved.
//

class TemperatureUnitDetail: TableDetail {
    
    // MARK: - 🐤 继承 Taylor
    override func onPrepare() {
        super.onPrepare()
        items = [["K", "℃", "℉"]]
        title = LocalizedString(R.Pref.TemperatureUnit.rawValue)
    }
    
    override func getItemView<T : NSObject, C : UITableViewCell>(tableView: UITableView, indexPath: NSIndexPath, data: T?, cell: C) -> UITableViewCell {
        let item = items[indexPath.section][indexPath.row]
        cell.textLabel?.text = item
        if item == getPref(R.Pref.TemperatureUnit.rawValue) {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        cell.selectionStyle = .Default
        return cell
    }
    
    // MARK: 💙 UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        putString(R.Pref.TemperatureUnit.rawValue, items[indexPath.section][indexPath.row])
        tableView.reloadData() // TODO: 动画效果不好，消失的太快
    }
}
