#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MagickWand.h"
#import "LabeledActivityIndicatorView.h"

typedef	enum{
	Sepia,
	OilPaint,
	Negate,
	Charcoal,
	Solarize,
	Sketch,
	Spread,
	Swirl,
	Blur,
	Implode,
	Emboss,
	Vignette,
	Shade,
	Flip
}EffectType;

@protocol FlipbackDelegate

- (void) flipback:(EffectType)type;
- (void) returnback:(id)sender;

@end


@interface PhotoProcessViewController : UIViewController <UIActionSheetDelegate, 
UIScrollViewDelegate,
UIImagePickerControllerDelegate,
UIPopoverControllerDelegate,
UINavigationControllerDelegate,
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
	UITabBar	*_tabbar;
	
	CGImageRef _beforeImage;
	EffectType currentType;
	
	ADBannerView *banner;

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
@property (nonatomic, retain) UITabBar	*tabbar;

@property (nonatomic, assign) CGImageRef beforeImage;
@property(nonatomic, retain)  ADBannerView *banner;


@end