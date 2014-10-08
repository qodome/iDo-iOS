//
//

#import <UIKit/UIKit.h>

@interface FDGraphView : UIView

// Data
@property (nonatomic, strong) NSArray *dataPoints;

// Style
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic) CGFloat dataPointsXoffset;
// -- colors
@property (nonatomic, strong) UIColor *dataPointColor;
@property (nonatomic, strong) UIColor *dataPointStrokeColor;
@property (nonatomic, strong) UIColor *linesColor;

// Behaviour
@property (nonatomic) BOOL autoresizeToFitData;

@property(nonatomic,strong) NSMutableArray *pointXArr;
@property(nonatomic,strong) NSMutableArray *pointYArr;

@end
