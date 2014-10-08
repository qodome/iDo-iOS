//
//

#import <Foundation/Foundation.h>
#import "FDGraphView.h"

@class FDGraphScrollView;

@protocol FDCaptionGraphViewDelegate <NSObject>
-(void)tapedCloserIndex:(int)index withPointX:(CGFloat)PointX;

@end

@interface FDGraphScrollView : UIScrollView

@property (nonatomic, strong) FDGraphView *graphView;

@property (nonatomic,weak) id<FDCaptionGraphViewDelegate> fDGraphViewDelegate;

@property (nonatomic) int numberOfDataPointsInEveryPage;

- (void)setDataPoints:(NSArray *)dataPoints;


//// -- colors
@property (nonatomic, strong) UIColor *dataPointColorAfterTaped;

@end
