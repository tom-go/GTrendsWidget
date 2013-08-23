#import <Foundation/Foundation.h>
#import "TrendsData.h"
#import "common.h"

@interface InfiniteScrollView : UIScrollView <UIScrollViewDelegate>
@property(nonatomic, copy) NSString *useCustomQuery;
@property(nonatomic, retain) NSMutableString *customQuery;
@property(nonatomic, retain) TrendsData *trendsData;
@property(nonatomic, retain) CADisplayLink *tickerDisplayLink;
- (void)stopAutoScroll;
- (void)startAutoScroll;
@end