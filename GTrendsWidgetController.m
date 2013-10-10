#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "Reachability.h"
#import "BBWeeAppController-Protocol.h"
#import "common.h"
#import "TrendsInfoView.h"
#import "InfiniteScrollView.h"
#import "TrendsData.h"

static NSBundle *_GTrendsWidgetWeeAppBundle = nil;

@interface GTrendsWidgetController: NSObject <BBWeeAppController, TrendsDataDelegate, UIGestureRecognizerDelegate>
@property(nonatomic, retain) UIView *view;
@property(nonatomic, assign) CGFloat viewWidth;
@end

@interface GTrendsWidgetController()
@property(nonatomic, copy) NSString *feedURL;
@property(nonatomic, copy) NSString *useCustomQuery;
@property(nonatomic, retain) NSMutableString *customQuery;
@property(nonatomic, assign) BOOL forceReloading;
@property(nonatomic, retain) Reachability *reachability;
@property(nonatomic, retain) TrendsData *trendsData;
@property(nonatomic, assign) BOOL nowLoading;
@end

@implementation GTrendsWidgetController
+ (void)initialize {
    _GTrendsWidgetWeeAppBundle = [[NSBundle bundleForClass:[self class]] retain];
}

- (id)init {
    self = [super init];
    if(self) {
        _viewWidth = 316;
    }
    return self;
}

- (void)dealloc {
    RELEASE_SAFELY(_reachability);
    RELEASE_SAFELY(_trendsData);
    RELEASE_SAFELY(_feedURL);
    RELEASE_SAFELY(_useCustomQuery);
    RELEASE_SAFELY(_customQuery);
    RELEASE_SAFELY(_view);
    [super dealloc];
}

- (void) loadSettings {
    NSDictionary* settings = [NSDictionary dictionaryWithContentsOfFile:PREFPATH];
    if( !settings )
    {
        self.feedURL        = @"http://www.google.com/trends/hottrends/atom/feed?pn=p1";
        self.useCustomQuery = @"NO";
        self.customQuery    = [NSMutableString stringWithString:@"http://m.yahoo.com/apple/onesearch?p=__QUERY__"];
        self.forceReloading = NO;
        settings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                self.feedURL,        @"gTrendsURL",
                                                self.useCustomQuery, @"useCustomQuery",
                                                self.customQuery,    @"customQuery",
                                                self.forceReloading, @"forceReloading",
                                                nil];
        [settings writeToFile:PREFPATH atomically:YES];
    }
    else{
        self.feedURL        = [settings objectForKey:@"gTrendsURL"];
        self.useCustomQuery = [settings objectForKey:@"useCustomQuery"];
        self.customQuery    = [settings objectForKey:@"customQuery"];
        self.forceReloading = [[settings objectForKey:@"forceReloading"] boolValue];
    }
}

- (void)removeSubviews {
    [self invalidateDisplayLink];
    [[_view viewWithTag:TAG_SCROLL_VIEW] removeFromSuperview];
    [[_view viewWithTag:TAG_INFO_VIEW] removeFromSuperview];
}

- (void)loadPlaceholderView {
    // This should only be a placeholder - it should not connect to any servers or perform any intense data loading operations.
    // All widgets are 316 points wide. Image size calculations match those of the Stocks widget.
    if( !_view ){
        _view = [[UIView alloc] initWithFrame:(CGRect){CGPointZero, {[self viewWidth], [self viewHeight]}}];
        _view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _view.clipsToBounds = YES;

        UIImage* bgImg = [UIImage imageWithContentsOfFile:WALLPAPER_IMG];
        UIImage* stretchableBgImg = [bgImg stretchableImageWithLeftCapWidth:floorf(bgImg.size.width / 2.f)
                                                               topCapHeight:floorf(bgImg.size.height / 2.f)];
        UIImageView *backgroundView = [[UIImageView alloc] initWithImage:stretchableBgImg];
        backgroundView.frame = CGRectInset(_view.bounds, 2.f, 0.f);
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_view addSubview:backgroundView];
        [backgroundView release];

        UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(reloadRanking:)];
        longPressGesture.delegate = (id)self;
        [_view addGestureRecognizer:longPressGesture];
        [longPressGesture release];
    }
}

- (void)loadFullView {

    [self loadSettings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNetworkChange:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    NSString *hostName = [[NSURL URLWithString:self.feedURL] host];
    self.reachability = [Reachability reachabilityWithHostName:hostName];
    
    [self updateTrends:self.forceReloading];

}

- (void)updateTrends:(BOOL)forceReleoading {
    self.trendsData = [[[TrendsData alloc] init] autorelease];
    self.trendsData.delegate = self;
    self.trendsData.trendsURL = self.feedURL;

    [self.trendsData updateTrends:forceReleoading];
}

- (void)saveTrendsIfNecessary {
    if( !self.trendsData.hasCachedRanking || self.trendsData.rankingUpdated || self.trendsData.needsFullUpdate ){
        [[NSFileManager defaultManager] removeItemAtPath:CACHEPATH error:nil];
        [self.trendsData.trends writeToFile:CACHEPATH atomically:NO];
    }
}

- (void)loadInfoView:(NSString *)info withType:(InfoType)type {

    [self removeSubviews];

    TrendsInfoView *infoView = [[TrendsInfoView alloc] initWithFrame:(CGRect){CGPointZero, {[self viewWidth], [self viewHeight]}}];
    infoView.info = info;
    infoView.infoType = type;
    infoView.feedURL = self.feedURL;
    infoView.tag = TAG_INFO_VIEW;
    [infoView tile];

    [_view addSubview:infoView];
    [infoView release];
}

- (void)loadScrollView {

    [self removeSubviews];

    CGRect frame = CGRectMake(2, 0, [self viewWidth], [self viewHeight]);
    InfiniteScrollView* scrollView = [[InfiniteScrollView alloc] initWithFrame:frame];
    scrollView.useCustomQuery = self.useCustomQuery;
    scrollView.customQuery = self.customQuery;
    scrollView.trendsData = self.trendsData;
    scrollView.tag = TAG_SCROLL_VIEW;

    [_view addSubview:scrollView];
    [scrollView release];
}

- (void)invalidateDisplayLink {
    InfiniteScrollView *scrollView = (InfiniteScrollView *)[_view viewWithTag:TAG_SCROLL_VIEW];
    [scrollView destroyDisplayLink];
}

- (void)unloadView {

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_reachability stopNotifier];
    
    [self invalidateDisplayLink];

    RELEASE_SAFELY(_reachability);
    RELEASE_SAFELY(_trendsData);
    RELEASE_SAFELY(_feedURL);
    RELEASE_SAFELY(_useCustomQuery);
    RELEASE_SAFELY(_customQuery);
    RELEASE_SAFELY(_view);
}

- (void)reloadRanking:(UILongPressGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self updateTrends:YES];
            break;
        default:
            break;
    }
}

- (float)viewWidth {
    return _viewWidth;
}

- (float)viewHeight {
    return GT_VIEW_HEIGHT;
}

- (void)handleNetworkChange:(NSNotification *)notice {

    Reachability *currentReachability = [notice object];

    if([currentReachability isEqual:self.reachability]) {
        NetworkStatus remoteHostStatus = [self.reachability currentReachabilityStatus];
        if(remoteHostStatus != NotReachable && !self.nowLoading ){
            // Try loading data if the scrollView does not exit.
            if( ![_view viewWithTag:TAG_SCROLL_VIEW] ) {
                [self updateTrends:YES];
            }
            [self.reachability stopNotifier];
        }
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(int)interfaceOrientation {
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        _viewWidth = 476;
    }
    else {
        if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
           interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            if([[UIScreen mainScreen] bounds].size.height < 568){
                _viewWidth = 476;
            }
            else{
                _viewWidth = 564;
            }
        }
        else{
            _viewWidth = 316;
        }
    }
}

#pragma mark -
#pragma mark TrendsDataDelegate
- (void)willBeginLoadingTrends {
    self.nowLoading = YES;
    [self loadInfoView:MSG_LOADING withType:TypeSpinner];
}

- (void)didFinishLoadingTrends {
    if( !self.trendsData.trends || self.trendsData.trends.count < 1 ) {
        [self loadInfoView:MSG_ERROR_LOADING withType:TypeInfo];
    }
    else {
        [self loadScrollView];
        [self saveTrendsIfNecessary];
        [(InfiniteScrollView *)[_view viewWithTag:TAG_SCROLL_VIEW] startAutoScroll];
    }
    self.nowLoading = NO;
}

- (void)didFailLoadingTrendsWithError:(NSError *)error {
    switch( [error code] ) {
        case NSURLErrorTimedOut:
            // -1001
            [self loadInfoView:MSG_ERROR_TIMEOUT withType:TypeNone];
            break;
        case NSURLErrorNotConnectedToInternet:
            // -1009
            [self.reachability startNotifier];
            [self loadInfoView:MSG_OFFLINE withType:TypeNone];
            break;
        default:
            [self loadInfoView:MSG_ERROR_LOADING withType:TypeInfo];
            break;
    }
    self.nowLoading = NO;
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

    if (touch.view != gestureRecognizer.view && [touch.view isKindOfClass:[UIButton class]]) {
        if( [[[UIDevice currentDevice] systemVersion] floatValue] < 6.0 ) {
            // Fix me : Emulating UIControlEvent if iOS version is under 6.0.
            // Could not fire the action method of infoButton(UIButton) on infoView without following code.
            [(UIButton *)touch.view sendActionsForControlEvents:UIControlEventTouchUpInside];

            return NO;
        }
    }
    return YES;
}

@end
