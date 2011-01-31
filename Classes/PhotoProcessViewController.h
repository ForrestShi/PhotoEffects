#import <UIKit/UIKit.h>
#import "MagickWand.h"

#import <AudioToolbox/AudioToolbox.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "LabeledActivityIndicatorView.h"

typedef	enum{
	Sepia,
	OilPaint
}EffectType;

@protocol FlipbackDelegate

- (void) flipback:(EffectType)type;

@end


@interface PhotoProcessViewController : UIViewController <UIActionSheetDelegate, 
UIImagePickerControllerDelegate,
UIPopoverControllerDelegate,
UINavigationControllerDelegate,
MFMailComposeViewControllerDelegate,
FlipbackDelegate> {
	UIImageView *_imageView;
	UISlider* _slider1;
	UISlider* slider2;
	BOOL	needSlider1;
	BOOL	needSlider2;
	
	LabeledActivityIndicatorView* _activity;
	SystemSoundID alertSoundID;
	
	UIImagePickerController * _picker;
	UIPopoverController* _popover;
	UIToolbar *_toolbar;
	
	CGImageRef _beforeImage;
	EffectType currentType;
}

- (IBAction)loadImage:(id)sender;
- (IBAction)shareImage:(id)sender;
- (IBAction)pickupEffect:(id)sender;

@property (nonatomic, retain) LabeledActivityIndicatorView* activity;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UISlider* slider1;
@property (nonatomic, retain) UISlider* slider2;
@property (nonatomic, assign) EffectType currentType;

@property (nonatomic, retain) UIPopoverController* popover;
@property (nonatomic, retain) UIImagePickerController *picker;

@property (nonatomic, retain) UIToolbar *toolbar;

@property (nonatomic, assign) CGImageRef beforeImage;


@end