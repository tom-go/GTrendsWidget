#import <Foundation/Foundation.h>
#import "common.h"

@protocol TrendsDataDelegate
@required
- (void)willBeginLoadingTrends;
- (void)didFinishLoadingTrends;
- (void)didFailLoadingTrendsWithError:(NSError *)error;
@end

@interface TrendsData : NSObject <NSURLConnectionDelegate, NSXMLParserDelegate>
@property(nonatomic, copy) NSString *trendsURL;
@property(nonatomic, retain) NSMutableArray *trends;
@property(nonatomic, assign) BOOL hasCachedRanking;
@property(nonatomic, assign) BOOL rankingUpdated;
@property(nonatomic, assign) BOOL needsFullUpdate;
@property(nonatomic, assign) NSObject<TrendsDataDelegate> *delegate;
- (id)init;
- (void)updateTrends:(BOOL)forceReloading;
@end