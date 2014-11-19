//
//  Copyright (c) 2014年 NY. All rights reserved.
//

// 1 怎样写reloadGraph() -> 画布清空?
import UIKit

class ScrolledChart: UIView, UIScrollViewDelegate {
    var lineChart: LineChart!
    var scrollView: UIScrollView!
    var pageCountForScrollView: Float = 0
    
    var xAxisPointSizeHeight = 4.0 // 坐标点高度
    var xAxisPointSizeWidth = 1.5 // 坐标点宽度
    var edgeInsets: UIEdgeInsets = UIEdgeInsetsMake(10, 15, 15, 15) // lineChart与scrollView之间的边界
    
    var titleInYAXisMax:String = ""
    
    // MARK: - lifeCycle
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override convenience init(frame: CGRect) {
        self.init(frame: frame, pageCount: 0, titleInYAXisMax: " ")
    }
    
    init(frame: CGRect, pageCount: Float, titleInYAXisMax: String) {
        super.init(frame: frame)
        backgroundColor = UIColor.clearColor()
        pageCountForScrollView = pageCount
        self.titleInYAXisMax = titleInYAXisMax
        // 生成 scrollView
        scrollView = UIScrollView(frame: CGRectMake(edgeInsets.left, edgeInsets.top, frame.size.width - edgeInsets.left - edgeInsets.right, frame.size.height - edgeInsets.top))
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.contentSize = CGSizeMake(scrollView.frame.width *  CGFloat(pageCountForScrollView), scrollView.frame.height)
        lineChart = LineChart(frame: CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height))
        scrollView.addSubview(lineChart)
        //Y轴
        //画Y坐标
        //画线
        var line = UILine(frame:CGRectMake(edgeInsets.left, edgeInsets.top, 2, frame.height - edgeInsets.bottom - edgeInsets.top))
        addSubview(line)
        println("frame - \(line.frame)")
        //画点
        var pointSize = CGSize(width: xAxisPointSizeHeight, height: xAxisPointSizeWidth)
        //addSubview(UICirclePoint(frame: CGRectMake(edgeInsets.left, edgeInsets.top, pointSize.width, pointSize.height)))
        // 添加 label
        let maxLabelHeight: CGFloat = 6.0
        let maxLabelRect = CGRectMake(0 , edgeInsets.top - maxLabelHeight / 2 , edgeInsets.left, maxLabelHeight)
        addSubview(addAXisLabel(titleInYAXisMax, rect: maxLabelRect))
    }
    
    /**add label的方法 */
    func addAXisLabel(text: String, rect:CGRect) ->UILabel {
        var label = UILabel(frame:rect)
        label.font = UIFont(name: "HelveticaNeue", size: 5)
        label.text = text
        label.textAlignment = NSTextAlignment.Center
        label.textColor = UIColor.blackColor()
        return label
    }
    
}
