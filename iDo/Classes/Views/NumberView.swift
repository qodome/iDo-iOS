//
//  Copyright (c) 2014年 NY. All rights reserved.
//

class NumberView: UIView {
    
    var integerLabel: UILabel!
    var decimalLabel: UILabel!
    var superscript: UILabel!
    var minusLabel: UILabel!
    var textColor: UIColor = UIColor.blackColor() {
        didSet {
            integerLabel.textColor = textColor
            decimalLabel.textColor = textColor
            superscript.textColor = textColor
            minusLabel.textColor = textColor
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        integerLabel = UILabel()
        integerLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 100)
        integerLabel.text = "--"
        integerLabel.sizeToFit()
        integerLabel.frame.origin.x = (frame.width - integerLabel.frame.width) / 2
        addSubview(integerLabel) // 整数
        decimalLabel = UILabel()
        decimalLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 50)
        decimalLabel.frame.origin.y = integerLabel.frame.origin.y + integerLabel.frame.height / 2
        addSubview(decimalLabel) // 小数，下标(subscript)
        superscript = UILabel()
        superscript.font = UIFont(name: "HelveticaNeue-Thin", size: 46)
        superscript.text = "°"
        superscript.sizeToFit()
        superscript.frame.origin = CGPointMake(integerLabel.frame.origin.x + integerLabel.frame.width, integerLabel.frame.origin.y + 12)
        addSubview(superscript) // 上标
        minusLabel = UILabel()
        minusLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 100)
        minusLabel.text = "-"
        minusLabel.sizeToFit()
        minusLabel.hidden = true
        addSubview(minusLabel) // 符号
    }
    
    func setValue(value: Double) {
        let integerValue = abs(Int(value))
        let decimalValue = Int((abs(value) - Double(integerValue)) * 10)
        
        println(integerValue)
        println(decimalValue)
        let s = "\(integerValue)"
        var kerning: CGFloat = 0
        if integerValue >= 100 || (integerValue >= 10 && integerValue < 20) { // 减小字间距
            kerning = 10
            let attributedString = NSMutableAttributedString(string: s)
            attributedString.addAttribute(NSKernAttributeName as String, value: NSNumber(double: -10), range: NSMakeRange(0, countElements(s)))
            integerLabel.attributedText = attributedString
        } else {
            integerLabel.text = s
        }
        integerLabel.sizeToFit()
        integerLabel.frame.size = CGSizeMake(integerLabel.frame.width + kerning, integerLabel.frame.height) // 宽度补10防止切边，不要用居中对齐，减小的时候会偏
        frame.size = CGSizeMake(integerLabel.frame.width * 2, integerLabel.frame.height)
        integerLabel.frame.origin.x = (frame.width - integerLabel.frame.width) / 2
        decimalLabel.text = ".\(decimalValue)"
        decimalLabel.sizeToFit()
        decimalLabel.frame.origin = CGPointMake(integerLabel.frame.origin.x + integerLabel.frame.width, integerLabel.frame.origin.y + integerLabel.frame.height - decimalLabel.frame.height - 10)
        let x = integerLabel.frame.origin.x
        decimalLabel.frame.origin.x = x + integerLabel.frame.width
        decimalLabel.hidden = decimalValue == 0
        superscript.frame.origin.x = x + integerLabel.frame.width
        minusLabel.frame.origin.x = x - minusLabel.frame.width
        minusLabel.hidden = value >= 0
    }
}
