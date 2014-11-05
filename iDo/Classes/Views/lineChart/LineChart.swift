//
//  Copyright (c) 2014年 NY. All rights reserved.
//

import UIKit

protocol ScrolledChartDataSource  {
    func allNumberOfPointsInSection(scrolledChart: LineChart) ->Int // 每段的所以点数
    func numberOfSectionsInScrolledChart(scrolledChart: LineChart) ->Int // 段数
    func numberOfPointsInScrolledChart(scrolledChart: LineChart) ->Int // 数据源的点数
    func scrolledChart(scrolledChart: LineChart, keyForItemAtPointNumber pointNumber: Int) ->Int //点对应的key
    func scrolledChart(scrolledChart: LineChart, valueForItemAtKey key: Int) ->CGFloat //点对应的value
    func maxDataInScrolledChart(scrolledChart: LineChart) ->CGFloat // 最大值
    func scrolledChart(scrolledChart: LineChart, titleInXAXisPointLabelInSection section: Int) ->String
}

protocol ScrolledChartDelegate  {
    func scrolledChart(scrolledChart: LineChart, didClickItemAtPointNumber pointNumber: Int)
}


class LineChart: UIView {
    let constMin: CGFloat = 20.0
    var xAxisPointSizeWidth = 1.5 // 坐标点宽度
    var xAxisPointSizeHeight = 4.0 // 坐标点高度
    var xAxisLineHeight = CGFloat(2.0) // 线的宽度
    var edgeInsets: UIEdgeInsets = UIEdgeInsetsMake(5, 0, 15, 10) // lineChart与scrollView之间的边界
    var spaceWithPoints: CGFloat = 0.0 // 每个section的长度
    var dataPointsXoffset: CGFloat = 0.0//点得间隔
    var graphPoints: [CGPoint] = []
    var dataSource: ScrolledChartDataSource?
    var delegate: ScrolledChartDelegate?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        var tapGestureRcongnizer = UITapGestureRecognizer(target: self, action: "lineChartClicked:")
        addGestureRecognizer(tapGestureRcongnizer)
        backgroundColor = UIColor.clearColor()
    }
    
    override func drawRect(rect: CGRect) {
        var context: CGContextRef = UIGraphicsGetCurrentContext()
        var sectionNumber = dataSource?.numberOfSectionsInScrolledChart(self)
        println("sectionNumber - \(sectionNumber)")
        if sectionNumber == 0 {
            return
        }
        let maxLabelHeight: CGFloat = 6.0
        //画X坐标
        spaceWithPoints = (frame.width - edgeInsets.left - edgeInsets.right) / CGFloat(sectionNumber! - 1)
        //画线
        var xLineFirstPoint = CGPointMake(edgeInsets.left, frame.height - edgeInsets.bottom )
        var xLineSecondPoint = CGPointMake(frame.width - edgeInsets.right, frame.height - edgeInsets.bottom )
        drawLine(xLineFirstPoint, secondPoint: xLineSecondPoint)
        //drawLine(context, withGraphPoints: xAXisPoints)
        for var i = 0; i < sectionNumber; i++ {
            var xValue = edgeInsets.left + CGFloat(i) * spaceWithPoints
            var yValue = frame.height - edgeInsets.bottom - CGFloat(xAxisPointSizeHeight)
            var pointSize = CGSize(width: xAxisPointSizeWidth, height: xAxisPointSizeHeight)
            //画点
            //添 label
            let spaceWithmaxLabelAndLine: CGFloat = 6.0
            let xLabelString = dataSource?.scrolledChart(self, titleInXAXisPointLabelInSection: i) // 代理方法
            addAXisLabel(xLabelString!, rect: CGRectMake(xValue, yValue + spaceWithmaxLabelAndLine,spaceWithPoints, maxLabelHeight))
        }
        //画图
            var eDrawingWidth, eDrawingHeight, min, max: CGFloat!
            max = (dataSource?.maxDataInScrolledChart(self))! // max 值 -->计算得到
            min = constMin// 定死
            var spacePointsCount = dataSource?.allNumberOfPointsInSection(self)
            eDrawingWidth =  spaceWithPoints
            eDrawingHeight = frame.height - edgeInsets.bottom - (CGPointZero.y + edgeInsets.top)
            if spacePointsCount == 0 {
                //没有数据
                return
            }
            if spacePointsCount == 1 {
                //TODO: - 对 spacePointsCount == 1 处理
                return
            }
            dataPointsXoffset = eDrawingWidth / CGFloat(spacePointsCount! - 1)
            var numberOfData = dataSource?.numberOfPointsInScrolledChart(self)
            for var i = 0; i < numberOfData; i++ {
                var key = dataSource?.scrolledChart(self, keyForItemAtPointNumber: i)
                var dataPointValues = dataSource?.scrolledChart(self, valueForItemAtKey: key!)
                var x, y: CGFloat!
                x = edgeInsets.left + CGFloat(key!) * dataPointsXoffset
                y = edgeInsets.top + CGFloat((max - dataPointValues!) * eDrawingHeight / (max - min))
                graphPoints.append(CGPointMake(x, y))
            }
            //drawLine(context, withGraphPoints: graphPoints)
        //draw line
        for var i = 0; i < numberOfData! - 1; i++ {
            var firstPoint = graphPoints[i]
            var secondPoint = graphPoints[i + 1]
            var firstKey = dataSource?.scrolledChart(self, keyForItemAtPointNumber: i)
            var secondKey = dataSource?.scrolledChart(self, keyForItemAtPointNumber: i + 1)
            //println("key - \(firstKey)  \(secondKey)")
            if (secondKey! - firstKey!) < 10 {
                drawLine(firstPoint, secondPoint: secondPoint)
            }
        }
    }
    
    /**draw point的方法 */
    func drawPoint(ellipseRect: CGRect, withContext context: CGContextRef) {
        CGContextAddEllipseInRect(context, ellipseRect)
        CGContextSetLineWidth(context, 1)
        UIColor.whiteColor().setStroke()
        UIColor.whiteColor().setFill()
        CGContextFillEllipseInRect(context, ellipseRect)
        CGContextStrokeEllipseInRect(context, ellipseRect)
    }
    
    /**draw line的方法 */
    func drawLine(firstPoint: CGPoint, secondPoint: CGPoint) {
        var path: UIBezierPath = UIBezierPath()
        path.lineWidth = 1.0
        path.moveToPoint(firstPoint)
        path.addLineToPoint(secondPoint)
        path.lineCapStyle = kCGLineCapRound
        UIColor.whiteColor().set()
        path.strokeWithBlendMode(kCGBlendModeNormal, alpha: 1.0)
    }

    /**add label的方法 */
    func addAXisLabel(text: String, rect:CGRect) ->UILabel {
        var label = UILabel(frame:rect)
        label.font = UIFont(name: "HelveticaNeue", size: 5)
        label.text = text
        label.textAlignment = NSTextAlignment.Left
        label.textColor = UIColor.blackColor()
        addSubview(label)
        return label
    }
    
    /**GestureRcongnizer Handler */
    func lineChartClicked(tapGestureRecongnizer: UITapGestureRecognizer) {
        let tapPoint = tapGestureRecongnizer.locationInView(self)
        var spaceList: [CGFloat] = []
        for var i = 0; i < dataSource?.numberOfPointsInScrolledChart(self); i++ {
            spaceList.append(abs(tapPoint.x - graphPoints[i].x))
        }
        var min = CGFloat(MAXFLOAT)
        var minNumber = -1
        for var i = 0; i < spaceList.count; i++ {
            if spaceList[i] < min {
                min = spaceList[i]
                minNumber = i
            }
        }
        var clickedPoint = dataSource?.scrolledChart(self, keyForItemAtPointNumber: minNumber)
        delegate?.scrolledChart(self, didClickItemAtPointNumber: clickedPoint!)
    }
}
