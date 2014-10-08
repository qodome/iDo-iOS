//
//

#import "FDGraphView.h"

@interface FDGraphView()

@property (nonatomic, strong) NSNumber *maxDataPoint;
@property (nonatomic, strong) NSNumber *minDataPoint;

@end

@implementation FDGraphView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self fDGraphViewUIInit];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
       // NSLog(@"gview-coder");
        [self fDGraphViewUIInit];
    }
    return self;
}


-(void)fDGraphViewUIInit {
    _edgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    _dataPointColor = [UIColor whiteColor];
    _dataPointStrokeColor = [UIColor whiteColor];
    _linesColor = [UIColor whiteColor];
    _autoresizeToFitData = NO;
    _dataPointsXoffset = (320 - 20) / 100.0;
    self.backgroundColor = [UIColor clearColor];
    self.pointYArr = [@[] mutableCopy];
    self.pointXArr = [@[] mutableCopy];
}

- (NSNumber *)maxDataPoint {
    if (_maxDataPoint) {
        return _maxDataPoint;
    } else {
        __block CGFloat max = ((NSNumber *)self.dataPoints[0]).floatValue;
        [self.dataPoints enumerateObjectsUsingBlock:^(NSNumber *n, NSUInteger idx, BOOL *stop) {
            if (n.floatValue > max)
                max = n.floatValue;
        }];
        return @(max);
    }
}

- (NSNumber *)minDataPoint {
    if (_minDataPoint) {
        return _minDataPoint;
    } else {
        __block CGFloat min = ((NSNumber *)self.dataPoints[0]).floatValue;
        [self.dataPoints enumerateObjectsUsingBlock:^(NSNumber *n, NSUInteger idx, BOOL *stop) {
            if (n.floatValue < min)
                min = n.floatValue;
        }];
        return @(min);
    }
}

- (CGFloat)widhtToFitData {
    CGFloat res = 0;
    
    if (self.dataPoints) {
        res += (self.dataPoints.count - 1)*self.dataPointsXoffset; // space occupied by data points
        res += (self.edgeInsets.left + self.edgeInsets.right) ; // lateral margins;
    }
    
    return res;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // STYLE
    // lines color
    [self.linesColor setStroke];
    // lines width
    CGContextSetLineWidth(context, 2);
    
    // CALCOLO I PUNTI DEL GRAFICO
    NSInteger count = self.dataPoints.count;
    CGPoint graphPoints[count];
    
    CGFloat drawingWidth, drawingHeight, min, max;
    
    drawingWidth = rect.size.width - self.edgeInsets.left - self.edgeInsets.right;
    NSLog(@"drawingwidth--%f",drawingWidth);
    drawingHeight = rect.size.height - self.edgeInsets.top - self.edgeInsets.bottom;
    min = ((NSNumber *)[self minDataPoint]).floatValue;
    max = ((NSNumber *)[self maxDataPoint]).floatValue;
    NSLog(@"dataoffx-%f",self.dataPointsXoffset);
    if (count > 1) {
        for (int i = 0; i < count; ++i) {
            CGFloat x, y, dataPointValue;
            
            dataPointValue = ((NSNumber *)self.dataPoints[i]).floatValue;
            
            x = self.edgeInsets.left + self.dataPointsXoffset*i;
            if (max != min)
                y = rect.size.height - ( self.edgeInsets.bottom + drawingHeight*( (dataPointValue - min) / (max - min) ) );
            else // il grafico si riduce a una retta
                y = rect.size.height/2;
            
            graphPoints[i] = CGPointMake(x, y);
           // NSLog(@"yy-%f rect--%@",graphPoints[i].y, NSStringFromCGRect(rect));
            self.pointXArr[i] = [NSNumber numberWithFloat:graphPoints[i].x];
            self.pointYArr[i] = [NSNumber numberWithFloat:graphPoints[i].y];
        }
    } else if (count == 1) {
        // pongo il punto al centro del grafico
        graphPoints[0].x = drawingWidth/2;
        graphPoints[0].y = drawingHeight/2;
        self.pointXArr[0] = [NSNumber numberWithFloat:graphPoints[0].x];
        self.pointYArr[0] = [NSNumber numberWithFloat:graphPoints[0].y];
    } else {
        return;
    }
    
    // DISEGNO IL GRAFICO
    CGContextAddLines(context, graphPoints, count);
    CGContextStrokePath(context);
    
    if (count == 1) {
        for (int i = 0; i < count; ++i) {
            CGRect ellipseRect = CGRectMake(graphPoints[i].x-3, graphPoints[i].y-3, 6, 6);
            CGContextAddEllipseInRect(context, ellipseRect);
            CGContextSetLineWidth(context, 3);
            [self.dataPointStrokeColor setStroke];
            [self.dataPointColor setFill];
            CGContextFillEllipseInRect(context, ellipseRect);
            CGContextStrokeEllipseInRect(context, ellipseRect);
        }

    }
    
}

#pragma mark - Custom setters

- (void)changeFrameWidthTo:(CGFloat)width {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
}

- (void)setDataPointsXoffset:(CGFloat)dataPointsXoffset {
    _dataPointsXoffset = dataPointsXoffset;
    
    if (self.autoresizeToFitData) {
        CGFloat widthToFitData = [self widhtToFitData];
       // NSLog(@"datapointCount-%d",self.dataPoints.count);
        if (widthToFitData > self.frame.size.width) {
            [self changeFrameWidthTo:widthToFitData];
        }
    }
}

- (void)setAutoresizeToFitData:(BOOL)autoresizeToFitData {
    _autoresizeToFitData = autoresizeToFitData;
    
    CGFloat widthToFitData = [self widhtToFitData];
    if (widthToFitData > self.frame.size.width) {
        [self changeFrameWidthTo:widthToFitData];
    }
}

- (void)setDataPoints:(NSArray *)dataPoints {
    _dataPoints = dataPoints;
    
    if (self.autoresizeToFitData) {
        CGFloat widthToFitData = [self widhtToFitData];
        if (widthToFitData > self.frame.size.width) {
            [self changeFrameWidthTo:widthToFitData];
        }
    }
}

@end
