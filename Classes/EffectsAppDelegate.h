#import <UIKit/UIKit.h>


@class PhotoProcessViewController;

@interface EffectsAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	PhotoProcessViewController *viewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) PhotoProcessViewController *viewController;
@end