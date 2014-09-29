//
//  WeekCell.swift
//  Olive-ios
//
//  Created by billsong on 14-9-9.
//  Copyright (c) 2014年 hongDing. All rights reserved.
//
class WeekCell: UITableViewCell {
    
    var weekButton: UIButton!
    var weekDateLabel: UILabel!
    var weekLable: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        weekButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        weekButton.titleLabel?.font = UIFont.boldSystemFontOfSize(12.0)
        weekButton.frame = CGRectMake(10, 12, 36, 36)
        weekButton.layer.cornerRadius = 18
        weekButton.enabled = false
        contentView.addSubview(weekButton)
        
        weekLable = UILabel(frame: (weekButton?.frame)!)
        weekLable.textAlignment = NSTextAlignment.Center
        weekLable.font = UIFont.boldSystemFontOfSize(12.0)
        weekLable.textColor = UIColor.whiteColor()
        contentView.addSubview(weekLable)
        
        weekDateLabel = UILabel(frame: CGRectMake(70, 0, 200, 60))
        weekDateLabel.font = UIFont.boldSystemFontOfSize(15.0)
        weekDateLabel.textColor = UIColor.darkTextColor()
        contentView.addSubview(weekDateLabel)

        var line: UIView = UIView()
        line.frame = CGRectMake(65, 59.5, 320, 0.5)
        line.backgroundColor = UIColor.lightGrayColor()
        contentView.addSubview(line)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
