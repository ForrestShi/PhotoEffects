    //
//  AboutViewController.m
//  ABCPhotoEffects
//
//  Created by forrest on 11-1-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "Appirater.h"


@implementation AboutViewController
@synthesize delegate = _delegate;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
		//NSLog(@"init with nil");
    }
    return self;
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


#pragma mark 
#pragma mark Actions

- (IBAction) writeReview:(id)sender
{
	[Appirater userDidSignificantEvent:YES];
}

- (IBAction) ReturnBack:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(returnback:)]) {
		[self.delegate performSelector:@selector(returnback:) withObject:nil];
	}
}

-(IBAction)writeEmail:(id)sender {
	MFMailComposeViewController *mailer =
	[[MFMailComposeViewController alloc] init];
	mailer.delegate = self;
	
	[mailer setToRecipients: [NSArray arrayWithObject: 
							  @"design4app@gmail.com"]];
	mailer.mailComposeDelegate = self;
	[mailer setSubject:@"About Photo Effects"];//"];
	[mailer setMessageBody:@"" isHTML: NO];
	mailer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self presentModalViewController:mailer animated:YES];
	[mailer release];
}
# pragma mark -
# pragma mark MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController*)mailer
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError*)error {
	[mailer dismissModalViewControllerAnimated:YES];
}


@end
