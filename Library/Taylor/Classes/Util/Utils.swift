//
//  Copyright (c) 2014年 NY. All rights reserved.
//

let SCREEN_WIDTH = UIScreen.mainScreen().bounds.width
let SCREEN_HEIGHT = UIScreen.mainScreen().bounds.height
let TEMP_IMAGE = UIImage()

enum MyStyle: Int {
    case Default
    case Transparent
}

extension UIViewController {
    
    func setToolbarStyle(style: MyStyle) {
        switch style {
        case .Transparent:
            navigationController?.toolbar.setBackgroundImage(TEMP_IMAGE, forToolbarPosition:
                .Any, barMetrics: .Default)
            navigationController?.toolbar.setShadowImage(TEMP_IMAGE, forToolbarPosition: .Any)
            navigationController?.toolbar.tintColor = UIColor.whiteColor()
        default:
            println("haha")
        }
    }
    
    func setNavigationBarStyle(style: MyStyle) {
        switch style {
        case .Transparent: // 透明导航栏
            automaticallyAdjustsScrollViewInsets = false // 默认全屏风格
            navigationController?.navigationBar.setBackgroundImage(TEMP_IMAGE, forBarMetrics: .Default)
            navigationController?.navigationBar.shadowImage = TEMP_IMAGE
            navigationController?.navigationBar.barStyle = .Black
            navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        default: // 还原导航栏
            navigationController?.navigationBar.setBackgroundImage(nil, forBarMetrics: .Default)
            navigationController?.navigationBar.shadowImage = nil
            navigationController?.navigationBar.barStyle = .Default
            navigationController?.navigationBar.tintColor = UIColor.colorWithHex(APP_COLOR)
        }
    }
}

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

extension UIImageView {
    
    /** 圆形 */
    class func roundedView(view: UIView, cornerRadius: CGFloat, borderColor: UIColor, borderWidth: CGFloat) {
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = true
        view.layer.borderColor = borderColor.CGColor
        view.layer.borderWidth = borderWidth
    }
}

extension UILabel {
    
    /** 计算字符串高度 */
    func size(text: String, width: Double) -> CGSize {
        return NSString(string: text).boundingRectWithSize(CGSize(width: width, height: DBL_MAX),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: self.font],
            context: nil).size
    }
    
    func size(text: String) -> CGSize {
        return size(text, width: DBL_MAX)
    }
}

// http://stackoverflow.com/questions/24092884/get-nth-character-of-a-string-in-swift-programming-language
extension String {
    
    subscript (i: Int) -> String {
        return String(Array(self)[i])
    }
    
    subscript (r: Range<Int>) -> String {
        var start = advance(startIndex, r.startIndex)
        var end = advance(startIndex, r.endIndex)
        return substringWithRange(Range(start: start, end: end))
    }
}

func LocalizedString(key: String) -> String {
    return NSLocalizedString(key, comment: "")
}

func Log(format: String, args: CVarArgType) { // TODO: 怎样传递CVarArgType...进去
    NSLog("🔵 \(format)", args)
}


func getExtension(path: String) -> String {
    let name = path.lastPathComponent
    let range = name.rangeOfString(".")
    return range == nil ? "" : name.substringFromIndex(range!.endIndex)
}

func getDirectory(path: String) -> String {
    // utf16Count不一定准确 参见http://stackoverflow.com/questions/24037711/get-the-length-of-a-string
    let name = path.lastPathComponent
    return path.substringToIndex(advance(path.startIndex, countElements(path) - countElements(name)))
}
