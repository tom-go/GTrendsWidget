#import "TrendsInfoView.h"
@interface TrendsInfoView()
@property(nonatomic, retain) UIAlertView *alertView;
@end

@implementation TrendsInfoView
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if( self ) {
    }
    return self;
}

- (void)dealloc {
    // alertView should be dismissed if InfoView is to be dealloced.
    [_alertView dismissWithClickedButtonIndex:1 animated:YES];

    [_alertView release];
    [_info release];
    [super dealloc];
}

- (void)tile {

    UIFont *infoFont = [UIFont boldSystemFontOfSize:16.f];
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    infoLabel.font = infoFont;
    infoLabel.text = self.info;
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.backgroundColor = [UIColor clearColor];

    CGSize labelSize = [self.info sizeWithFont:infoFont forWidth:CGRectGetWidth(self.frame) lineBreakMode:UILineBreakModeMiddleTruncation];
    [infoLabel setFrame:(CGRect){CGPointZero, labelSize}];

    UIView *containerView = [[UIView alloc] initWithFrame:infoLabel.frame];

    id typeObject = nil;

    switch( self.infoType ) {
        case TypeSpinner:
            typeObject = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            break;
        case TypeInfo:
            typeObject = [[UIButton buttonWithType:UIButtonTypeInfoLight] retain];
            break;
        default:
            break;
    }
    if ( typeObject ) {
        // typeObject should be in square shape (labelSize.height x labelSize.height).
        [typeObject setFrame:(CGRect){CGPointZero, {labelSize.height, labelSize.height}}];

        CGFloat margin = 6.f;

        // Expand the width of containerView for additional object
        CGRect containerFrame = containerView.frame;
        containerFrame.size.width += CGRectGetWidth([typeObject frame]) + margin;
        [containerView setFrame:containerFrame];

        if( [typeObject isKindOfClass:[UIActivityIndicatorView class]] ) {
            // Spinner should be placed on left. Shift infoLabel to right.
            CGRect infoLabelFrame = infoLabel.frame;
            infoLabelFrame.origin.x += CGRectGetWidth([typeObject frame]) + margin;
            [infoLabel setFrame:infoLabelFrame];
            [typeObject startAnimating];
        }
        else if( [typeObject isKindOfClass:[UIButton class]] ) {
            // Info button should be placed on right. Shift tyoeObject to right.
            CGRect typeObjectFrame = [typeObject frame];
            typeObjectFrame.origin.x += CGRectGetWidth(infoLabel.frame) + margin;
            [typeObject setFrame:typeObjectFrame];
            [typeObject addTarget:self action:@selector(infoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        }

        [containerView addSubview:typeObject];
        [typeObject release];
    }

    CGRect containerFrame = containerView.frame;
    containerFrame.origin.x = (CGRectGetWidth(self.frame)-CGRectGetWidth(containerView.frame))/2;
    containerFrame.origin.y = (CGRectGetHeight(self.frame)-CGRectGetHeight(containerView.frame))/2;
    [containerView setFrame:containerFrame];

    containerView.backgroundColor = [UIColor clearColor];
    containerView.tag = TAG_INFO_VIEW;
    [containerView addSubview:infoLabel];
    [infoLabel release];

    [self addSubview:containerView];
    [containerView release];
}

#pragma mark -
#pragma mark UIButton Callback
- (void)infoButtonPressed {
    self.alertView = [[[UIAlertView alloc] init] autorelease];
    self.alertView.delegate = self;
    self.alertView.title = MSG_ERROR_LOADING;
    self.alertView.message = @"   If you are experiencing this error\n"
                              "  several times, please try following\n"
                              "  procedure.\n"
                              "  \n"
                              "   1. Open GoogleTrends in Safari.\n"
                              "   2. Sign in to Google.\n"
                              "   3. Close Safari.\n"
                              "   4. Try Gtrends Widget later.\n";
    ((UILabel *)[[self.alertView subviews] objectAtIndex:1]).textAlignment = UITextAlignmentLeft;
    [self.alertView addButtonWithTitle:@"Launch Safari"];
    [self.alertView addButtonWithTitle:@"Cancel"];
    
    [self.alertView show];
}

#pragma mark -
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if( buttonIndex == 0 ) {
        NSString *siteURL = [self.feedURL stringByReplacingOccurrencesOfString:@"/atom/feed?" withString:@"#"];
        NSURL *url = [NSURL URLWithString:siteURL];
        [[UIApplication sharedApplication] openURL:url];
    }
}
@end
