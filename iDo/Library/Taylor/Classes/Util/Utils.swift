//
//  Copyright (c) 2014年 NY. All rights reserved.
//

let TEMP_IMAGE = UIImage()

extension UIColor {
    
    /** 16进制颜色 */
    class func colorWithHex(hexColor: Int) -> UIColor {
        return UIColor(
            red: CGFloat((hexColor & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hexColor & 0xFF00) >> 8) / 255.0,
            blue: CGFloat(hexColor & 0xFF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}
