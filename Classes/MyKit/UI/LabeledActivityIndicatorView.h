#import <Foundation/Foundation.h>

@interface LabeledActivityIndicatorView : UIView {
	BOOL shown;
	UIViewController *controller;
	NSString	*_labelText;
}
@property (nonatomic, retain) UIViewController *controller;
@property (nonatomic, retain) NSString	*labelText;


-(LabeledActivityIndicatorView *) initWithController:(UIViewController *)ctrl andText:(NSString *)text;
-(void) show;
-(void) hide;

@end
