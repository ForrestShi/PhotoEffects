//
//  AboutViewController.h
//  ABCPhotoEffects
//
//  Created by forrest on 11-1-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>


@protocol FlipbackDelegate;

@interface AboutViewController : UIViewController<MFMailComposeViewControllerDelegate> {
	id<FlipbackDelegate> _delegate;
}

@property(nonatomic ,assign) id<FlipbackDelegate> delegate;
- (IBAction) writeEmail:(id)sender;
- (IBAction) writeReview:(id)sender;
- (IBAction) ReturnBack:(id)sender;

@end
