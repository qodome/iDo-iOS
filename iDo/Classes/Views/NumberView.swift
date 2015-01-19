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
        integerLabel.frame.origin = CGPointMake((frame.width - integerLabel.frame.width) / 2, (frame.height - integerLabel.frame.height) / 2) // 居中
        addSubview(integerLabel) // 整数
        let x = integerLabel.frame.origin.x
        let y = integerLabel.frame.origin.y
        decimalLabel = UILabel()
        decimalLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 50)
        decimalLabel.text = ".-"
        decimalLabel.sizeToFit()
        decimalLabel.frame.origin = CGPointMake(x + integerLabel.frame.width, y + integerLabel.frame.height - decimalLabel.frame.height - 10)
        addSubview(decimalLabel) // 小数，下标(subscript)
        superscript = UILabel()
        superscript.font = UIFont(name: "HelveticaNeue-Thin", size: 46)
        superscript.text = "°"
        superscript.sizeToFit()
        superscript.frame.origin = CGPointMake(x + integerLabel.frame.width, y + 12)
        addSubview(superscript) // 上标
        minusLabel = UILabel()
        minusLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 100)
        minusLabel.text = "-"
        minusLabel.sizeToFit()
        minusLabel.frame.origin = CGPointMake(x - minusLabel.frame.width, y)
        addSubview(minusLabel) // 符号
        decimalLabel.hidden = true
        minusLabel.hidden = true
    }
    
    func setValue(value: Double) {
        var a: Double = 0
        let decimalValue = abs(Int(modf(value, &a) * 10))
        let integerValue = abs(Int(a))
        let s = "\(integerValue)"
        var kerning: CGFloat = 0
//        if integerValue >= 100 || (integerValue >= 10 && integerValue < 20) { // 减小字间距
//            kerning = 10
//            let attributedString = NSMutableAttributedString(string: s)
//            attributedString.addAttribute(NSKernAttributeName as String, value: NSNumber(double: -10), range: NSMakeRange(0, countElements(s)))
//            integerLabel.attributedText = attributedString
//        } else {
            integerLabel.text = s
//        }
        integerLabel.sizeToFit()
//        integerLabel.frame.size.width = integerLabel.frame.width + kerning // 宽度补10防止切边，不要用居中对齐，减小的时候会偏
        integerLabel.frame.origin.x = (frame.width - integerLabel.frame.width) / 2
        let x = integerLabel.frame.origin.x
        decimalLabel.text = ".\(decimalValue)"
        decimalLabel.sizeToFit()
        decimalLabel.frame.origin.x = x + integerLabel.frame.width
        superscript.frame.origin.x = x + integerLabel.frame.width
        minusLabel.frame.origin.x = x - minusLabel.frame.width
        // 隐藏
        decimalLabel.hidden = decimalValue == 0
        minusLabel.hidden = value >= 0
    }
}
