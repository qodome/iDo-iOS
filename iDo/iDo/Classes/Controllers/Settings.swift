//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Settings: UITableViewController {
   
    let IDOLOGREDCOLOR = Util.ColorFromRGB(0xFB414D)
    let minLowestTemperature:Float = 26
    let maxLowestTemperature:Float = 36
    let minHighestTemperature:Float = 37
    let maxHighesTemperature:Float = 47
    
    @IBOutlet weak var lowLabel: UILabel!
    @IBOutlet weak var highLabel: UILabel!
    @IBOutlet weak var lAlarmLabel: UILabel!
    @IBOutlet weak var lNoticeSwitch: UISwitch!
    @IBOutlet weak var hAlarmLabel: UILabel!
    @IBOutlet weak var HNoticeSwitch: UISwitch!
    @IBOutlet weak var lowestTemperatureSlider: UISlider!
    @IBOutlet weak var lowestTemperatureLabel: UILabel!
    @IBOutlet weak var hightestTemperatureSlider: UISlider!
    @IBOutlet weak var highestTemperatureLabel: UILabel!
    
    // MARK: - lifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //国际化
        navigationItem.title = NSLocalizedString("setting", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
        lowLabel.text =  NSLocalizedString("Minimum temperature", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
        highLabel.text = NSLocalizedString("Maximum temperature", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
        lAlarmLabel.text = NSLocalizedString("low temperature alarm", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
        hAlarmLabel.text = NSLocalizedString("High temperature alarm", tableName: "Localization", bundle: NSBundle.mainBundle(), value: "", comment: "")
        
        lNoticeSwitch.on = Util.isLowTNotice()
        HNoticeSwitch.on = Util.isHighTNotice()
        lowestTemperatureSlider.tag = 0
        lowestTemperatureSlider.value = (Util.lowestTemperature() - minLowestTemperature ) / (maxLowestTemperature - minLowestTemperature)
       lowestTemperatureLabel.text =  NSString(format: "%.1f", Util.lowestTemperature())
        
        hightestTemperatureSlider.tag = 1
        hightestTemperatureSlider.value = (Util.HighestTemperature() - minHighestTemperature) / (maxHighesTemperature - minHighestTemperature)
        highestTemperatureLabel.text = NSString(format: "%.1f", Util.HighestTemperature())
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        recoverTranslucentedTabBar()
       // navigationController?.navigationBar.tintColor = IDOLOGREDCOLOR
    }
    
    // MARK: - custom method
    
    func recoverTranslucentedTabBar(){
        tabBarController?.tabBar.backgroundImage = nil
        tabBarController?.tabBar.shadowImage = nil
        tabBarController?.tabBar.barStyle = UIBarStyle.Default
//        tabBarController?.tabBar.translucent = true
        tabBarController?.tabBar.tintColor = IDOLOGREDCOLOR
    }

    // MARK: - action
    
    @IBAction func BacktoMainVC(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func switchLowTNotice(sender: UISwitch) {
        let isLowTNotice = Util.isLowTNotice()
        if sender.on != isLowTNotice {
            Util.setIsLowTNotice(sender.on)
        }
    }
    
    @IBAction func switchHighTNotice(sender: UISwitch) {
        let isHighTNotice = Util.isHighTNotice()
        if sender.on != isHighTNotice {
            Util.setIsHighTNotice(sender.on)
        }
    }
    
    @IBAction func changeTemperature(sender: UISlider) {
        if sender.tag == 0 {
            //lowest
            let currentLowestTemperature = minLowestTemperature +  (maxLowestTemperature - minLowestTemperature) * sender.value
            lowestTemperatureLabel.text = NSString(format: "%.1f", currentLowestTemperature)
            Util.setLowestTemperature(currentLowestTemperature)
        }
        else {
            //highest
            let currentHighestTemperature = minHighestTemperature +  (maxHighesTemperature - minHighestTemperature) * sender.value
            highestTemperatureLabel.text = NSString(format: "%.1f", currentHighestTemperature)
            Util.setHighestTemperature(currentHighestTemperature)
        }
    }
    
}
