#import "InfiniteScrollView.h"

@interface InfiniteScrollView()
@property(nonatomic, retain) NSMutableArray *visibleItems;
@property(nonatomic, retain) UIView *itemContainerView;
@property(nonatomic, assign) NSInteger leftImageIndex;
@property(nonatomic, assign) NSInteger rightImageIndex;
@property(nonatomic, assign) NSInteger touchedItemIndex;
@end

@implementation InfiniteScrollView
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {

        self.contentSize = CGSizeMake(5000, frame.size.height);
        _visibleItems = [[NSMutableArray alloc] init];
        _itemContainerView = [[UIView alloc] init];
        _itemContainerView.frame = (CGRect){CGPointZero, {self.contentSize.width, self.frame.size.height}};
        _itemContainerView.userInteractionEnabled= NO;

        [self addSubview:_itemContainerView];
        [self setShowsHorizontalScrollIndicator:NO];
        
        UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchURL)];
        [self addGestureRecognizer:tapGesture];
        [tapGesture release];
    }
    return self;
}

- (void)dealloc {

    [self stopAutoScroll];
    [_tickerDisplayLink invalidate];
    _tickerDisplayLink = nil;

    [_useCustomQuery release];
    [_customQuery release];
    [_trendsData release];
    [_visibleItems release];
    [_itemContainerView release];

    [super dealloc];
}

#pragma mark -
#pragma mark Layout
// recenter content periodically to achieve impression of infinite scrolling
- (void)recenterIfNecessary {
    CGPoint currentOffset = [self contentOffset];
    CGFloat contentWidth = [self contentSize].width;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0;
    CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX);

    if (distanceFromCenter > (contentWidth / 4.0)) {
         self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);

        // move content by the same amount so it appears to stay still
        for (UIView *item in _visibleItems) {
            CGPoint center = [_itemContainerView convertPoint:item.center toView:self];
            center.x += (centerOffsetX - currentOffset.x);
            item.center = [self convertPoint:center toView:_itemContainerView];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if(_trendsData.trends.count > 0) {
        [self recenterIfNecessary];
        // tile content in visible bounds
        CGRect visibleBounds = [self convertRect:[self bounds] toView:_itemContainerView];
        CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
        CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
        [self tileLabelsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
    }
}

#pragma mark -
#pragma mark Label Tiling
- (UIView *)insertItemView:(int)index {

    NSMutableDictionary *elementsDict = [_trendsData.trends objectAtIndex:index];

    NSString *rank = [NSString stringWithFormat:@"%@: ", [[NSNumber numberWithUnsignedInt:index+1] stringValue]];
    UIFont *rankFont = [UIFont boldSystemFontOfSize:17.f];
    UILineBreakMode mode = UILineBreakModeMiddleTruncation;
    CGSize rankSize = [rank sizeWithFont:rankFont forWidth:316.f lineBreakMode:mode];
    UILabel *rankLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, rankSize.width, rankSize.height)];
    [rankLabel setFont:rankFont];
    [rankLabel setText:rank];
    [rankLabel setTextColor:[UIColor whiteColor]];
    [rankLabel setBackgroundColor:[UIColor clearColor]];

    // init query label
    NSString *query = [elementsDict objectForKey:@"title"];
    UIFont *queryFont = [UIFont boldSystemFontOfSize:17.f];
    CGSize querySize = [query sizeWithFont:queryFont forWidth:1250.f lineBreakMode:mode];
    UILabel *queryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, querySize.width, querySize.height)];
    [queryLabel setFont:queryFont];
    [queryLabel setText:query];
    [queryLabel setTextColor:[UIColor whiteColor]];
    [queryLabel setBackgroundColor:[UIColor clearColor]];

    // init prev rank label
    NSMutableString *prevRank = [[NSMutableString alloc] initWithString:@" Prev.Rank: "];
    NSString *stringToAppend = [elementsDict objectForKey:@"prev_rank"] ? : @"-";
    [prevRank appendString:stringToAppend];
    UIFont *prevRankFont = [UIFont boldSystemFontOfSize:11.f];
    CGSize prevRankSize = [prevRank sizeWithFont:prevRankFont forWidth:316.f lineBreakMode:mode];
    prevRankSize = CGSizeMake(prevRankSize.width+2.f, prevRankSize.height); // +2.f is just a fine adjustment
    UILabel *prevRankLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, querySize.height, prevRankSize.width, prevRankSize.height)];
    [prevRankLabel setFont:prevRankFont];
    [prevRankLabel setText:prevRank];
    [prevRankLabel setTextColor:[UIColor whiteColor]];
    [prevRankLabel setBackgroundColor:[UIColor clearColor]];
    [prevRank release];
/*
    // init traffic label
    NSMutableString *trafficString = [[NSMutableString alloc] init];
    NSString *stringToAppend = [elementsDict objectForKey:@"traffic"]?:@"-";
    [trafficString appendString:stringToAppend];
    [trafficString appendString:@" searches"];
    UIFont *prevRankFont = [UIFont boldSystemFontOfSize:11.f];
    CGSize prevRankSize = [trafficString sizeWithFont:prevRankFont forWidth:316.f lineBreakMode:mode];
    prevRankSize = CGSizeMake(prevRankSize.width, prevRankSize.height); // +2.f is just a fine adjustment
    UILabel *prevRankLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, querySize.height, prevRankSize.width, prevRankSize.height)];
    [prevRankLabel setFont:prevRankFont];
    [prevRankLabel setText:trafficString];
    [prevRankLabel setTextColor:[UIColor whiteColor]];
    [prevRankLabel setBackgroundColor:[UIColor clearColor]];
    [trafficString release];
*/
    // init arrow image view
    UIImage *arrowImage = nil;
    UIImageView *arrowView = nil;
    CGRect arrowFrame;

    int rankNo = [[elementsDict objectForKey:@"rank"] intValue];
    int prev_rankNo = [elementsDict objectForKey:@"prev_rank"] ?
                      [[elementsDict objectForKey:@"prev_rank"] intValue] :
                      21;
    if(prev_rankNo==0){
        arrowImage = nil;
    }
    else if(rankNo > prev_rankNo){
        arrowImage = [UIImage imageWithContentsOfFile:DOWN_ARROW_IMG];
    }
    else if(rankNo < prev_rankNo){
        arrowImage = [UIImage imageWithContentsOfFile:UP_ARROW_IMG];
    }

    arrowView = [[UIImageView alloc] init];
    arrowView.contentMode = UIViewContentModeScaleAspectFit;
    if(arrowImage) {
        arrowFrame = CGRectMake(0, 0, prevRankSize.height, prevRankSize.height);
        arrowView.image = arrowImage;
    }
    else{
        arrowFrame = CGRectZero;
    }
    [arrowView setFrame:arrowFrame];

    CGFloat widthLine1 = rankSize.width + querySize.width;
    CGFloat widthLine2 = arrowView.frame.size.width + prevRankSize.width;
    CGFloat itemWidth  = (widthLine1 >= widthLine2 ? widthLine1 : widthLine2) + GT_MARGIN;
    CGFloat itemHeight = querySize.height + prevRankSize.height ;

    // culc labels' origin.x
    CGRect frame = [rankLabel frame];
    frame.origin.x = GT_MARGIN;
    [rankLabel setFrame:frame];

    frame = [queryLabel frame];
    frame.origin.x = itemWidth - querySize.width;
    [queryLabel setFrame:frame];

    frame = [prevRankLabel frame];
    frame.origin.x = (itemWidth - prevRankSize.width) + 1;
    frame.origin.y = querySize.height;
    [prevRankLabel setFrame:frame];

    frame = [arrowView frame];
    frame.origin.x = itemWidth - (prevRankSize.width + frame.size.width);
    frame.origin.y = querySize.height;
    [arrowView setFrame:frame];

    UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, (GT_VIEW_HEIGHT-itemHeight)/2, itemWidth, itemHeight)];
    itemView.tag = index;

    [itemView addSubview:rankLabel];
    [itemView addSubview:queryLabel];
    [itemView addSubview:arrowView];
    [itemView addSubview:prevRankLabel];
    [_itemContainerView addSubview:itemView];

    [rankLabel release];
    [queryLabel release];
    [arrowView release];
    [prevRankLabel release];
    [itemView release];



    return [[_itemContainerView subviews] lastObject];
}

- (CGFloat)placeNewLabelOnRight:(CGFloat)rightEdge {
    
    UIView *itemView = [self insertItemView:_rightImageIndex];
    // add rightmost label at the end of the array
    [_visibleItems addObject:itemView];

    CGRect frame = [itemView frame];
    frame.origin.x = rightEdge;
    [itemView setFrame:frame];

    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewLabelOnLeft:(CGFloat)leftEdge {
    
    UIView *itemView = [self insertItemView:_leftImageIndex];
    // add leftmost label at the beginning of the array
    [_visibleItems insertObject:itemView atIndex:0];

    CGRect frame = [itemView frame];
    frame.origin.x = leftEdge - frame.size.width;
    [itemView setFrame:frame];

    return CGRectGetMinX(frame);
}

- (void)tileLabelsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX {
    // the upcoming tiling logic depends on there already being at least one label in the _visibleItems array, so
    // to kick off the tiling we need to make sure there's at least one label
    if ([_visibleItems count] == 0)
         [self placeNewLabelOnRight:minimumVisibleX];

    // add labels that are missing on right side
    UIView *lastLabel = [_visibleItems lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastLabel frame]);
    while (rightEdge < maximumVisibleX) {
        _rightImageIndex = _rightImageIndex+1 > _trendsData.trends.count-1 ? 0 : _rightImageIndex+1;
        rightEdge = [self placeNewLabelOnRight:rightEdge];
    }

    // add labels that are missing on left side
    UIView *firstLabel = [_visibleItems objectAtIndex:0];
    CGFloat leftEdge = CGRectGetMinX([firstLabel frame]);
    while (leftEdge > minimumVisibleX) {
        _leftImageIndex = _leftImageIndex-1 < 0 ? _trendsData.trends.count-1 : _leftImageIndex-1;
        leftEdge = [self placeNewLabelOnLeft:leftEdge];
    }

    // remove labels that have fallen off right edge
    lastLabel = [_visibleItems lastObject];
    while ([lastLabel frame].origin.x > maximumVisibleX) {
        [lastLabel removeFromSuperview];
        [_visibleItems removeLastObject];
        lastLabel = [_visibleItems lastObject];
        _rightImageIndex = _rightImageIndex-1 < 0 ? _trendsData.trends.count-1 : _rightImageIndex-1;
    }

    // remove labels that have fallen off left edge
    firstLabel = [_visibleItems objectAtIndex:0];
    while (CGRectGetMaxX([firstLabel frame]) < minimumVisibleX) {
        [firstLabel removeFromSuperview];
        [_visibleItems removeObjectAtIndex:0];
        firstLabel = [_visibleItems objectAtIndex:0];
        _leftImageIndex = _leftImageIndex+1 > _trendsData.trends.count-1 ? 0 : _leftImageIndex+1;
    }
}

#pragma mark -
#pragma mark timer event handler
- (void)timerDidFire:(CADisplayLink *)sender {
    if ( [_tickerDisplayLink isPaused] || self.tracking ) {
        return;
    }
    CGPoint p = self.contentOffset;
    p.x = p.x + 1.f;
    self.contentOffset = p;
}

#pragma mark -
#pragma mark auto scroll management
- (void)startAutoScroll {
    if(!self.tickerDisplayLink) {
        self.tickerDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerDidFire:)];
        [self.tickerDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.tickerDisplayLink.paused = NO;
}

- (void)stopAutoScroll {
    _tickerDisplayLink.paused = YES;
}

#pragma mark -
#pragma mark UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopAutoScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self startAutoScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self startAutoScroll];
    }
}

#pragma mark -
#pragma mark Launching URL
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

    CGPoint convPoint = [_itemContainerView convertPoint:point fromView:self];
    
    for(UIView *itemView in _visibleItems){
        CGRect itemFrame = [itemView frame];
        CGFloat minX = CGRectGetMinX(itemFrame);
        CGFloat maxX = CGRectGetMaxX(itemFrame);
        if(convPoint.x >= minX    && convPoint.x <= maxX){
            _touchedItemIndex = itemView.tag;
        }
    }
    id view = [super hitTest:point withEvent:event];
    return view;
}

- (void)launchURL {

    NSString *urlString = nil;
    NSMutableDictionary *itemDict = [self.trendsData.trends objectAtIndex:_touchedItemIndex];

    if(![self.useCustomQuery boolValue]){
        urlString = [itemDict objectForKey:@"landing_page"];
    }
    else{
        NSMutableString *tmpQuery = [[NSMutableString alloc] initWithString:_customQuery];
        [tmpQuery replaceOccurrencesOfString:@"__QUERY__"
                                  withString:[itemDict objectForKey:@"title"]
                                     options:NSLiteralSearch
                                       range:NSMakeRange(0, [tmpQuery length])];
        [tmpQuery replaceOccurrencesOfString:@"\n"
                                  withString:@""
                                     options:NSLiteralSearch
                                       range:NSMakeRange(0, [tmpQuery length])];
        urlString = [tmpQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [tmpQuery release];
    }

    NSURL *url = [NSURL URLWithString:urlString];

    if([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.title = @";-(";
        alert.message = @"No app is available that will accept the custom query.\nPlease check if it is valid.";
        [alert addButtonWithTitle:@"OK"];
        [alert show];
        [alert release];
    }
}
@end