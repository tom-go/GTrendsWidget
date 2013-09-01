#import "common.h"

@interface TrendsInfoView : UIView <UIAlertViewDelegate>
@property(nonatomic, retain) NSString *info;
@property(nonatomic, assign) InfoType infoType;
@property(nonatomic, assign) NSString *feedURL;
- (id)initWithFrame:(CGRect)frame;
- (void)tile;
@end

