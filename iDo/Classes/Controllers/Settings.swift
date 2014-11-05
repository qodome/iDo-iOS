//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class Settings: UITableViewController {
    
    let minLowestTemperature: Float = 26
    let maxLowestTemperature: Float = 36
    let minHighestTemperature: Float = 37
    let maxHighesTemperature: Float = 47
    
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
    
    // MARK: - 生命周期 (Lifecycle)
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedString("settings")
        lowLabel.text = LocalizedString("Minimum temperature")
        highLabel.text = LocalizedString("Maximum temperature")
        lAlarmLabel.text = LocalizedString("low temperature alarm")
        hAlarmLabel.text = LocalizedString("High temperature alarm")
        
        lNoticeSwitch.on = Util.isLowTNotice()
        HNoticeSwitch.on = Util.isHighTNotice()
        lowestTemperatureSlider.tag = 0
        lowestTemperatureSlider.value = (Util.lowestTemperature() - minLowestTemperature ) / (maxLowestTemperature - minLowestTemperature)
        lowestTemperatureLabel.text =  NSString(format: "%.1f", Util.lowestTemperature())
        
        hightestTemperatureSlider.tag = 1
        hightestTemperatureSlider.value = (Util.HighestTemperature() - minHighestTemperature) / (maxHighesTemperature - minHighestTemperature)
        highestTemperatureLabel.text = NSString(format: "%.1f", Util.HighestTemperature())
    }
    
    // MARK: - Action
    @IBAction func back(sender: AnyObject) {
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
        if sender.tag == 0 { // lowest
            let currentLowestTemperature = minLowestTemperature + (maxLowestTemperature - minLowestTemperature) * sender.value
            lowestTemperatureLabel.text = NSString(format: "%.1f", currentLowestTemperature)
            Util.setLowestTemperature(currentLowestTemperature)
        } else { // highest
            let currentHighestTemperature = minHighestTemperature + (maxHighesTemperature - minHighestTemperature) * sender.value
            highestTemperatureLabel.text = NSString(format: "%.1f", currentHighestTemperature)
            Util.setHighestTemperature(currentHighestTemperature)
        }
    }
}
