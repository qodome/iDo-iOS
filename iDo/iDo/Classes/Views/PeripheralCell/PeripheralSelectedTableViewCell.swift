//
//  PeripheralSelectedTableViewCell.swift
//  Olive-ios
//
//  Created by billsong on 14-9-18.
//  Copyright (c) 2014年 hongDing. All rights reserved.
//

import UIKit

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
