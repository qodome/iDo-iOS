
//

#import "FDGraphScrollView.h"
@interface FDGraphScrollView()

@property(nonatomic) CGFloat currentTapedX;
@property(nonatomic) UIView *dot;

@end

@implementation FDGraphScrollView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _graphView = [[FDGraphView alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, frame.size.width, frame.size.height)];
        [self buildUI];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
       _graphView = [[FDGraphView alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, self.frame.size.width, self.frame.size.height)];
       // NSLog(@"gsview-coder---%f",self.frame.size.height);
        [self buildUI];
    }
    return self;
}

-(void)buildUI {
    self.showsHorizontalScrollIndicator =  NO;
    _graphView.autoresizeToFitData = YES;
    self.backgroundColor = [UIColor whiteColor];
    _graphView.dataPointsXoffset = (320 - 20) / 100.0;
    [self addSubview:_graphView];
    self.dataPointColorAfterTaped = [UIColor clearColor];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(scrollViewTaped:)];
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (CGSize)contentSizeWithWidth:(CGFloat)width {
    return CGSizeMake(width, self.frame.size.height);
}

- (void)setDataPoints:(NSArray *)dataPoints {
    self.graphView.dataPoints = dataPoints;
    self.contentSize = [self contentSizeWithWidth:self.graphView.frame.size.width];
}

- (void)setNumberOfDataPointsInEveryPage:(int)numberOfDataPointsInEveryPage {
    NSLog(@"number--%d",numberOfDataPointsInEveryPage);
    _numberOfDataPointsInEveryPage = numberOfDataPointsInEveryPage;
    if (_numberOfDataPointsInEveryPage<=1) {
        NSLog(@"numberOfDatPointsInEveryPage must be  > 1");
    }
    else {
        _graphView.dataPointsXoffset = (self.frame.size.width - self.graphView.edgeInsets.left - self.graphView.edgeInsets.right)/(_numberOfDataPointsInEveryPage-1);
        NSLog(@"dataPointsOffset--%f",_graphView.dataPointsXoffset);
    }
}

- (void)scrollViewTaped:(UITapGestureRecognizer *) tapGestureRecognizer
{
    CGPoint touchPoint = [tapGestureRecognizer locationInView:self];
    NSLog(@"scrollViewTaped! At %f %f", touchPoint.x, touchPoint.y);
    //得到距离点击点最近的点的序号
    int closerIndex = [self indexForTapedWithTouchPoint:touchPoint];
    NSLog(@"closerIndex-%lu",(unsigned long)closerIndex);
    //画点
    if (self.dot) {
        [self closeTapedPointWithDot];
    }
    [self showTapedPointAtIndex:closerIndex];
    //代理方法 //
    if (self.fDGraphViewDelegate && [self.fDGraphViewDelegate respondsToSelector:@selector(tapedCloserIndex:withPointX:)]) {
        CGFloat pointX = [self.graphView.pointXArr[closerIndex] floatValue] - 3;
        [self.fDGraphViewDelegate tapedCloserIndex:closerIndex withPointX:pointX];
    }
}

-(void)showTapedPointAtIndex:(int) index {
    self.dot=[[UIView alloc]init];
    self.dot.frame = CGRectMake([self.graphView.pointXArr[index] floatValue] - 3 , [self.graphView.pointYArr[index] floatValue]-3 ,6 ,6);
    
    self.dot.backgroundColor = self.dataPointColorAfterTaped;
    //圆化
    self.dot.layer.cornerRadius = 3 ;
    self.dot.layer.masksToBounds = YES;
    
    [self addSubview:self.dot];
}

-(void)closeTapedPointWithDot {
    [self.dot removeFromSuperview];
}

-(int)indexForTapedWithTouchPoint:(CGPoint) touchPoint {
    //data source == 1
    if (self.graphView.dataPoints.count == 1) {
        return 0;
    }
    
    if (touchPoint.x <= self.graphView.edgeInsets.left) {
        return 0;
    }
    int index = -1;
   // CGFloat drawingWidth = self.contentSize.width - self.graphView.edgeInsets.left - self.graphView.edgeInsets.right;
    if (touchPoint.x >= self.graphView.dataPointsXoffset*(self.graphView.dataPoints.count - 1) + self.graphView.edgeInsets.left) {
        return (int)self.graphView.dataPoints.count - 1;
    }
    
    for (int i = 0; i < self.graphView.dataPoints.count; ++i) {
        CGFloat x;
        x = self.graphView.edgeInsets.left + self.graphView.dataPointsXoffset*i;
        if (touchPoint.x <= x) {
            CGFloat frontalX = self.graphView.edgeInsets.left + self.graphView.dataPointsXoffset*(i-1);
            if(touchPoint.x - frontalX > x - touchPoint.x) {
                //靠右
                index = i;
            }
            else {
                //靠左
                index = i-1;
            }
            return index;
        }
        
    }
    return index;
}

@end
