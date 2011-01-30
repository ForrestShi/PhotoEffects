#import "EffectsAppDelegate.h"
#import "PhotoProcessViewController.h"
#import "Appirater.h"

@implementation EffectsAppDelegate
@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];  
    window.backgroundColor = [UIColor blackColor];  
	
	viewController = [[PhotoProcessViewController alloc] init];
	
    [window addSubview:viewController.view];
	[window makeKeyAndVisible];
	
	[Appirater appLaunched:NO];
	
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
	[Appirater appEnteredForeground:NO];
}

- (void)dealloc {
    [viewController release];
	[window release];
	[super dealloc];
}
@end