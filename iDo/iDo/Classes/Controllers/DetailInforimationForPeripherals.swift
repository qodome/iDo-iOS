//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import CoreBluetooth

class DetailInforimationForPeripherals: UITableViewController {
    
    let detailInforId = "detailInforId"
    let IDOLOGREDCOLOR = Util.ColorFromRGB(0xFB414D)
    var currentPeripheral: CBPeripheral!
    
    // MARK: - life cyle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("\(currentPeripheral.description)")
//        navigationController?.navigationBar.tintColor = IDOLOGREDCOLOR
        tabBarController?.tabBar.tintColor = IDOLOGREDCOLOR
        navigationItem.title = NSLocalizedString("Detail Info", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
        
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(detailInforId, forIndexPath: indexPath) as UITableViewCell
        cell.selectionStyle = UITableViewCellSelectionStyle.None
        return setCellInformationWithIndexPath(indexPath, withCell: cell)
    }

    // MARK: - custom Method
    
    func setCellInformationWithIndexPath(indexPath: NSIndexPath, withCell cell: UITableViewCell)->UITableViewCell {
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = NSLocalizedString("Name", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
            cell.detailTextLabel?.text = currentPeripheral.name
        case 1:
            cell.textLabel?.text = NSLocalizedString("Number", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
            cell.detailTextLabel?.text = currentPeripheral.identifier.UUIDString
        default:println("error")
        }
        return cell
    }
}
