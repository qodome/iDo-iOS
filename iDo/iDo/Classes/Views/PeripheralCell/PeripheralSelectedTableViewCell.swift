//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class PeripheralSelectedTableViewCell: UITableViewCell {

    @IBOutlet var sTextLabel: UILabel?
    @IBOutlet var sDetailTextLabel: UILabel?
    @IBOutlet var sActivityIndictor:UIActivityIndicatorView?
    @IBOutlet var sImageView: UIImageView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
   }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
