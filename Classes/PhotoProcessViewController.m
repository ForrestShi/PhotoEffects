
#import "PhotoProcessViewController.h"
#import <opencv/cv.h>
#import "MyUIBox.h"
#import "MyImageKit.h"
#import "SHK.h"
#import "EffectsTableViewController.h"
#import "AboutViewController.h"

static NSString* message = @"More fun apps from us: http://DesignForApple.com, follow us with twitter.com/design4apple, email us with design4apple@gmail.com,thanks for your feedbacks in advance!";
static NSString* title = @"Sepia Pro App from DesignForApple.com";
#define TOOLBAR_HEIGHT_PAD 60 
#define TOOLBAR_HEIGHT 45

#define SLIDER_MAX 100
#define SLIDER_MIN 0
#define SLIDER_DEFAULT 50

#define ThrowWandException(wand) { \
char * description; \
ExceptionType severity; \
\
description = MagickGetException(wand,&severity); \
(void) fprintf(stderr, "%s %s %lu %s\n", GetMagickModule(), description); \
description = (char *) MagickRelinquishMemory(description); \
exit(-1); \
}

@interface PhotoProcessViewController (ADBannerViewDelegate) <ADBannerViewDelegate>

@end


@implementation PhotoProcessViewController

@synthesize imageView = _imageView;
@synthesize slider1 = _slider1 ,slider2;
@synthesize toolbar = _toolbar;
@synthesize tabbar = _tabbar;
@synthesize picker = _picker;
@synthesize popover = _popover;
@synthesize activity = _activity;
@synthesize beforeImage = _beforeImage;
@synthesize currentType;
@synthesize banner;

- (void)dealloc {
	AudioServicesDisposeSystemSoundID(alertSoundID);
	
	if (_beforeImage) {
		CGImageRelease(_beforeImage);
		_beforeImage = nil;
	}
	
	[_imageView release];
	[_activity  release];
	[_slider1 release];
	[slider2 release];
	[_toolbar release];
	[_picker release];
	[_popover release];
	[super dealloc];
}


#pragma mark 
#pragma mark ImageMagick



- (void) setCurrentType:(EffectType)newType
{
	currentType = newType;
	needSlider1 = YES;
	needSlider2 = NO;
	
	//	if (currentType == OilPaint) {
	//		needSlider1 = YES;
	//		needSlider2 = YES;
	//	}else if (currentType == Sepia) {
	//		needSlider1 = YES;
	//		needSlider2 = NO;
	//	}
}

- (CGImageRef) createStandardImage:(CGImageRef) image{
	 size_t width =  CGImageGetWidth(image);
	 size_t height = CGImageGetHeight(image);
	
	if (width >320 ) {
		height = height * 320/width;
		width = 320;
	}
	if (height > 480) {
		width = width * 480/height;
		height = 480;
	}
	
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, space,
											 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(space);
	CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), image);
	CGImageRef dstImage = CGBitmapContextCreateImage(ctx);
	CGContextRelease(ctx);
	return dstImage;
}

- (NSString*) effectName:(EffectType)effectType
{
	NSString* name = nil;
	switch (effectType) {
		case Sepia:
			name = @"Sepia";
			break;
		case OilPaint:
			name = @"Oil Painting";
			break;
		case Negate:
			name = @"Negate";
			break;
		case Charcoal:
			name = @"Charcoal";
			break;
		case Solarize:
			name = @"Solarize";
			break;
		case Sketch:
			name = @"Sketch";
			break;
		case Spread:
			name = @"Spread";
			break;
		case Swirl:
			name = @"Swirl";
			break;
		case Blur:
			name = @"Blur";
			break;
		case Implode:
			name = @"Implode";
			break;
		case Emboss:
			name = @"Emboss";
			break;
		case Vignette:
			name = @"Vignette";
			break;
		case Shade:
			name = @"Shade";
			break;
		case Flip:
			name = @"Flip";
			break;
		default:
			name=@"No Effect";
			break;
	}
	return name;
}

-(MagickBooleanType) filterOilPainting:(MagickWand*)magick_wand{
	MagickBooleanType status;
	
	float ratio1 = self.slider1.value/20;
	status = MagickOilPaintImage(magick_wand,ratio1);  //2
	status = MagickRadialBlurImage(magick_wand,1);  // 1
	return status;
}

-(MagickBooleanType) filterSepiaTone:(MagickWand*)magick_wand{
	float ratio1 = self.slider1.value*1.5 + 80;
	return MagickSepiaToneImage(magick_wand,
								ratio1 );
}

-(MagickBooleanType) filterSketch:(MagickWand*)magick_wand{	
	float ratio1 = self.slider1.value/20;
	//MagickSeparateImageChannel(magick_wand, GreenChannel);
	return MagickSketchImage( magick_wand,ratio1,0,0.5);
}

-(MagickBooleanType) filterSpread:(MagickWand*)magick_wand{
	float ratio = self.slider1.value*0.3; // (0, 10.0)
	return MagickSpreadImage(magick_wand,ratio /*const double radius*/);
}

-(MagickBooleanType) filterWave:(MagickWand*)magick_wand{
	float ratio1 = self.slider1.value*0.1; // (0, 10.0)
	float ratio2 = self.slider2.value+80;
	return MagickWaveImage(magick_wand,ratio1,160);
}

-(MagickBooleanType) filterRadialBlur:(MagickWand*)magick_wand{
	float ratio = self.slider1.value*0.2; // (0, 20.0)
	return MagickRadialBlurImage(magick_wand,ratio /*const double radius*/);
}

-(MagickBooleanType) filterNegate:(MagickWand*)magick_wand{
	float ratio = self.slider1.value;
	if (ratio < SLIDER_MAX/4) {
		return MagickNegateImage(magick_wand,FALSE);
	}else if (ratio < SLIDER_MAX/2 && ratio >= SLIDER_MAX/4) {
		MagickSeparateImageChannel(magick_wand,RedChannel);
		return MagickNegateImage(magick_wand,TRUE);
	}else if (ratio < SLIDER_MAX*3/4 && ratio >= SLIDER_MAX/2) {
		MagickSeparateImageChannel(magick_wand,BlueChannel);
		return MagickNegateImage(magick_wand,TRUE);
	}else {
		MagickSeparateImageChannel(magick_wand,GreenChannel);
		return MagickNegateImage(magick_wand,TRUE);
	}
}

-(MagickBooleanType) filterSolarize:(MagickWand*)magick_wand{
	float ratio = self.slider1.value*2.55; // (0, 255)
	return MagickSolarizeImage(magick_wand,ratio /*const double radius*/);
}
// long time 
-(MagickBooleanType) filterCharcoal:(MagickWand*)magick_wand{
	float ratio1 = self.slider1.value*0.05; // (0, 5.0)
	float ratio2 = 1.2;
	//MagickSeparateImageChannel(magick_wand, GreenChannel);
	return MagickCharcoalImage(magick_wand,ratio1,ratio2 );
}

-(MagickBooleanType) filterImplode:(MagickWand*)magick_wand{
	float ratio1 = (self.slider1.value - 70 ) *0.01; 
	return MagickImplodeImage(magick_wand,ratio1);
}

-(MagickBooleanType) filterEmboss:(MagickWand*)magick_wand{
	float ratio1 = self.slider1.value * 0.2 ; 
	return MagickEmbossImage(magick_wand,ratio1,1);
}

-(MagickBooleanType) filterVignette:(MagickWand*)magick_wand{
	float ratio1 = self.slider1.value * 2.55 ; 
	return MagickVignetteImage(magick_wand, ratio1, 255 - ratio1 , 5,5);
}

-(MagickBooleanType) filterShade:(MagickWand*)magick_wand{
	float ratio1 = self.slider1.value * 2.0 ; 
	return MagickShadeImage(magick_wand, MagickTrue, ratio1 , ratio1/6 );	
}

-(MagickBooleanType) filterFlip:(MagickWand*)magick_wand{
	float ratio = self.slider1.value;
	if (ratio < SLIDER_MAX/2) {
		return MagickFlipImage(magick_wand);	
	}else {
		return MagickFlopImage(magick_wand);
	}
}

-(MagickBooleanType) filterFrame:(MagickWand*)magick_wand{
	//return MagickEqualizeImage(magick_wand);
	float ratio = self.slider1.value;
	return MagickOrderedPosterizeImage(magick_wand, "h8x8o");
}
// multithread version

- (void) doFiltering:(id)cgImage {
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	CGImageRef srcCGImage = (CGImageRef)cgImage;
	
	const unsigned long width = CGImageGetWidth(srcCGImage);
	const unsigned long height = CGImageGetHeight(srcCGImage);
	// could use the image directly if it has 8/16 bits per component,
	// otherwise the image must be converted into something more common (such as images with 5-bits per component)
	// here we’ll be simple and always convert
	const char *map = "ARGB"; // hard coded
	const StorageType inputStorage = CharPixel;
	CGImageRef standardized = [self createStandardImage:srcCGImage];
	NSData *srcData1 = (NSData *) CGDataProviderCopyData(CGImageGetDataProvider(standardized));
	CGImageRelease(standardized);
	const void *bytes = [srcData1 bytes];
	const size_t length = [srcData1 length];
	MagickWandGenesis();
	MagickWand * magick_wand_local= NewMagickWand();
	MagickBooleanType status = MagickConstituteImage(magick_wand_local, width, height, map, inputStorage, bytes);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand_local);
	}
	
	// effects algorithm here
    
	switch (currentType) {
		case -1:
			//nothing to do
			break;
		case Sepia:
			status = [self filterSepiaTone:magick_wand_local];
			break;
		case OilPaint:
			status = [self filterOilPainting:magick_wand_local];
			break;
		case Negate:
			status = [self filterNegate:magick_wand_local];
			break;
		case Charcoal:
			status = [self filterCharcoal: magick_wand_local];
			break;
		case Solarize:
			status = [self filterSolarize:magick_wand_local];
			break;
		case Sketch:
			status = [self filterSketch:magick_wand_local];
			break;
		case Swirl:
			status = [self filterWave:magick_wand_local];
			break;
		case Spread:
			status = [self filterSpread:magick_wand_local];
			break;
		case Blur:
			status = [self filterRadialBlur:magick_wand_local];
			break;
		case Implode:
			status = [self filterImplode:magick_wand_local];
			break;
		case Emboss:
			status = [self filterEmboss:magick_wand_local];
			break;
		case Vignette:
			status = [self filterVignette:magick_wand_local];
			break;
		case Shade:
			status = [self filterShade:magick_wand_local];
			break;
		case Flip:
			status = [self filterFlip:magick_wand_local];
			break;
		default:
			break;
	}
	
	const int bitmapBytesPerRow = (width * strlen(map));
	const int bitmapByteCount = (bitmapBytesPerRow * height);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	char *trgt_image = malloc(bitmapByteCount);
	status = MagickExportImagePixels(magick_wand_local, 0, 0, width, height, map, CharPixel, trgt_image);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand_local);
	}
	magick_wand_local = DestroyMagickWand(magick_wand_local);
	MagickWandTerminus();
	CGContextRef context = CGBitmapContextCreate (trgt_image,
												  width,
												  height,
												  8, // bits per component
												  bitmapBytesPerRow,
												  colorSpace,
												  kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpace);
	CGImageRef cgimage = CGBitmapContextCreateImage(context);
	UIImage *image = [[UIImage alloc] initWithCGImage:cgimage];
	//NSLog(@"image size %f %f",image.size.width,image.size.height );
	[self.imageView	performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(hideProgressIndicator) withObject:nil waitUntilDone:YES];
	
	CGImageRelease(cgimage);
	CGContextRelease(context);
	[srcData1 release];
	free(trgt_image);
	[image release];
	[pool drain];
}


#pragma mark -
#pragma mark Utilities for intarnal use

- (void)showProgressIndicator:(NSString *)text {
	
	self.view.userInteractionEnabled = FALSE;
	self.activity.labelText = text;
	[self.activity show];
}

- (void)hideProgressIndicator {
	self.view.userInteractionEnabled = TRUE;
	[self.activity hide];
	AudioServicesPlaySystemSound(alertSoundID);
}



#pragma mark -
#pragma mark UIViewControllerDelegate

- (void)viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor blackColor];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Tink" ofType:@"aiff"] isDirectory:NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url, &alertSoundID);
	
	{
		UIScrollView	*scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
		scrollView.contentSize = self.imageView.frame.size;
		scrollView.scrollEnabled = YES;
		scrollView.contentMode = UIViewContentModeScaleAspectFit;
		scrollView.autoresizingMask = ( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		scrollView.maximumZoomScale = 2.5;
		scrollView.minimumZoomScale = 1.0;
		scrollView.clipsToBounds = YES;
		scrollView.delegate = self;
		[scrollView addSubview:self.imageView];
		
		//Tap event 
		UITapGestureRecognizer	*tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
		[scrollView addGestureRecognizer:tap];
		[tap release];
		
		[self.view addSubview:scrollView];
		[scrollView release];
	}
	[self.view addSubview:self.toolbar];
	[self.view addSubview:self.slider1];
	[self.view addSubview:self.banner];
    [self layoutForCurrentOrientation:NO];
	
}

- (void) tapAction
{
	[UIView animateWithDuration:.5 animations:^{
				_toolbar.alpha == 1.0 ? (_toolbar.alpha = 0):(_toolbar.alpha= 1.0);
			_slider1.alpha == 1.0 ? (_slider1.alpha = 0):(_slider1.alpha = 1.0);
	}];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation == UIInterfaceOrientationPortrait || 
	interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
}

-(void)adjustEffect:(id)sender{
	if(self.imageView.image){
		[self showProgressIndicator:[self effectName:currentType]];
		[self performSelectorInBackground:@selector(doFiltering:) withObject:self.beforeImage];
	}
}
#pragma mark 
#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView    // return a view that will be scaled. if delegate returns nil, nothing happens
{
	return self.imageView;
}

#pragma mark 
#pragma mark property 

- (LabeledActivityIndicatorView*) activity
{
	if (!_activity) {
		_activity = [[LabeledActivityIndicatorView alloc] initWithController:self andText:@"Rendering..."];
	}
	return _activity;
}

- (ADBannerView*) banner
{
	if(banner == nil)
    {
        [self createADBannerView];
    }
	return banner;
}
- (UIToolbar*) toolbar 
{
	if (!_toolbar) {
		_toolbar = [[UIToolbar alloc] init ];
		CGRect fullRect = [UIScreen mainScreen].applicationFrame;
		CGRect myBounds = self.view.bounds;
		UIBarButtonItem *loadItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
																				  target:self action:@selector(loadImage:)];
		
		UIBarButtonItem *effectsPickr = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																					  target:self action:@selector(pickupEffect:)];
		effectsPickr.title = @"Effects";
		UIBarButtonItem *aboutItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
																				   target:self action:@selector(about:)];
		
		UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																				   target:self action:@selector(shareImage:)];
		shareItem.title = @"Share";
		UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
		_toolbar.items = [NSArray arrayWithObjects:loadItem,spaceItem, effectsPickr,spaceItem, aboutItem, spaceItem,shareItem, nil];
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			_toolbar.frame = CGRectMake(0, CGRectGetMaxY(myBounds) - TOOLBAR_HEIGHT_PAD, fullRect.size.width,  TOOLBAR_HEIGHT_PAD);
		}else {
			_toolbar.frame = CGRectMake(0, CGRectGetMaxY(myBounds) - TOOLBAR_HEIGHT, fullRect.size.width,  TOOLBAR_HEIGHT);
		}
		
		_toolbar.barStyle = UIBarStyleBlackTranslucent;
		_toolbar.alpha = 1.0f;
		[spaceItem release];
		[shareItem release];
		[effectsPickr release];
		[aboutItem release];
	}
	return _toolbar;
}
- (UITabBar*) tabbar
{
	if (!_tabbar) {
	}
	return _tabbar;
}

- (UIPopoverController*) popover
{
	if (!_popover) {
		_popover = [[UIPopoverController alloc] initWithContentViewController:self.picker];
		[_popover setDelegate:self];
	}
	return _popover;
}

- (UIImagePickerController*) picker
{
	if (!_picker) {
		_picker = [[UIImagePickerController alloc] init];
		_picker.delegate = self;
	}
	return _picker;
}

- (void) setBeforeImage:(CGImageRef)newImage
{
	if (newImage == _beforeImage) {
		return;
	}
	CGImageRelease(_beforeImage);
	_beforeImage = CGImageCreateCopy(newImage);
}

- (UIImageView*) imageView
{
	if (!_imageView) {
		CGRect fullRect = [UIScreen mainScreen].applicationFrame;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			fullRect.origin.y = 66;
		}else {
			fullRect.origin.y = 50;
		}

		UIImage *defaultImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"jobs" ofType:@"png"]];
		_imageView = [[UIImageView alloc]initWithFrame:fullRect];
		_imageView.image = defaultImage;
		_imageView.contentMode = UIViewContentModeScaleAspectFit;
		_imageView.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
		CGImageRef standardImage = [self createStandardImage:_imageView.image.CGImage];
		self.beforeImage = standardImage;
		CGImageRelease(standardImage);
	}
	return _imageView;
}

- (UISlider*) slider1
{
	if (!_slider1) {
		CGRect fullRect = [UIScreen mainScreen].applicationFrame;
		CGRect slider = CGRectMake(fullRect.size.width/10, fullRect.size.height*0.8, fullRect.size.width*0.8, 10);
		_slider1 = [MyUIBox yellowSlider:slider withMax:SLIDER_MAX withMin:SLIDER_MIN withValue:SLIDER_DEFAULT withLabel:@"nil"];
		[_slider1 addTarget:self action:@selector(adjustEffect:) forControlEvents:UIControlEventValueChanged];
	}
	return _slider1;
}
//simplify , just have 1 slider1 now 
- (UISlider*) slider2
{
	return nil;
	
	//	if (!slider2) {
	//		CGRect fullRect = [UIScreen mainScreen].applicationFrame;
	//		CGRect slider = CGRectMake(fullRect.size.width/10, fullRect.size.height*0.7, fullRect.size.width*0.8, 10);
	//		slider2 = [MyUIBox yellowSlider:slider withMax:100 withMin:0 withValue:50 withLabel:@"nil"];
	//		[slider2 addTarget:self action:@selector(adjustEffect:) forControlEvents:UIControlEventValueChanged];
	//	}
	//	return slider2;
	
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	UIImagePickerControllerSourceType sourceType;
	if (buttonIndex == 0) {
		sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	} else if(buttonIndex == 1) {
		sourceType = UIImagePickerControllerSourceTypeCamera;
	} else if(buttonIndex == 2) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"jobs" ofType:@"png"];
		self.imageView.image = [UIImage imageWithContentsOfFile:path];
		CGImageRef standardImage = [self createStandardImage:_imageView.image.CGImage];
		self.beforeImage = standardImage;
		CGImageRelease(standardImage);	} 
	if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
		self.picker.sourceType = sourceType;
		[self presentModalViewController:self.picker animated:YES];
	}
}
#pragma mark -
#pragma mark IBAction

- (void) resetData
{
	currentType = 0;  // take 0 as default effect type  
	[self.slider1 setValue:SLIDER_DEFAULT];
}

- (IBAction)loadImage:(id)sender {
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		//NSLog(@"iPad");
		[self showPhotoLibrary:sender];
	}else {
		UIActionSheet *actionSheet;
		
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Photo"
												  delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
										 otherButtonTitles:@"From Photo Album", @"Capture With Camera",@"Handsome Guy", nil];
		actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
		[actionSheet showInView: self.imageView ];
		[actionSheet release];
	}
	[self resetData];
	
}

- (IBAction)shareImage:(id)sender {
	if(self.imageView.image) {
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[self.popover dismissPopoverAnimated:YES];
		}
		
		SHKItem *item = [SHKItem image:self.imageView.image title:title];
		item.text = message;// @"More Applications from us http://DesignForApple.com";
		
		// Get the ShareKit action sheet
		SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
		actionSheet.backgroundColor = [UIColor clearColor];
		// Display the action sheet
		// [actionSheet showFromToolbar:self.toolbar];
		[actionSheet showInView:self.view];
	}
}

- (IBAction)about:(id)sender {

	AboutViewController *avc = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		avc = [[AboutViewController alloc] initWithNibName:@"AboutViewController_iPad" bundle:nil];
	}else {
		avc = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
	}

	avc.delegate = self;
	avc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	[self presentModalViewController:avc animated:YES];
	[avc release];
}


-(IBAction)pickupEffect:(id)sender{
	
	EffectsTableViewController	*etvc = [[EffectsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	etvc.delegate = self;
	etvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:etvc animated:YES];
	[etvc release];
}

#pragma mark 
#pragma mark FlipbackDelegate
- (void) flipback:(EffectType)type
{
	[self dismissModalViewControllerAnimated:YES];
	//reset adjustment parameters
	[self.slider1 setValue:SLIDER_DEFAULT];
	//reset image
	self.imageView.image = [UIImage imageWithCGImage: self.beforeImage];
	self.currentType = (EffectType) type;
}

- (void) returnback:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

-(void) showPhotoLibrary:(id)sender
{	
	if (sender != nil) {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			[self.popover presentPopoverFromBarButtonItem:sender 
								 permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			
		}
	}
	
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
	UIImage* selectedImage = [info	objectForKey:@"UIImagePickerControllerOriginalImage"];
	CGImageRef standardImage = [self createStandardImage:selectedImage.CGImage];
	self.beforeImage = standardImage;
	CGImageRelease(standardImage);	
	self.imageView.image = selectedImage; //[MyImageKit scaleAndRotateImage:selectedImage];
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}
@end

@implementation PhotoProcessViewController (ADBannerViewDelegate)


-(void)createADBannerView
{
    // --- WARNING ---
    // If you are planning on creating banner views at runtime in order to support iOS targets that don't support the iAd framework
    // then you will need to modify this method to do runtime checks for the symbols provided by the iAd framework
    // and you will need to weaklink iAd.framework in your project's target settings.
    // See the iPad Programming Guide, Creating a Universal Application for more information.
    // http://developer.apple.com/iphone/library/documentation/general/conceptual/iPadProgrammingGuide/Introduction/Introduction.html
    // --- WARNING ---
	
    // Depending on our orientation when this method is called, we set our initial content size.
    // If you only support portrait or landscape orientations, then you can remove this check and
    // select either ADBannerContentSizeIdentifierPortrait (if portrait only) or ADBannerContentSizeIdentifierLandscape (if landscape only).
	NSString *contentSize;
	if (&ADBannerContentSizeIdentifierPortrait != nil)
	{
		contentSize = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifierLandscape;
	}
	else
	{
		// user the older sizes 
		contentSize = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? ADBannerContentSizeIdentifier320x50 : ADBannerContentSizeIdentifier480x32;
    }
	
    // Calculate the intial location for the banner.
    // We want this banner to be at the bottom of the view controller, but placed
    // offscreen to ensure that the user won't see the banner until its ready.
    // We'll be informed when we have an ad to show because -bannerViewDidLoadAd: will be called.
    CGRect frame;
    frame.size = [ADBannerView sizeFromBannerContentSizeIdentifier:contentSize];
    frame.origin = CGPointMake(0.0f, CGRectGetMinY(self.view.bounds));

    // Now to create and configure the banner view
    ADBannerView *bannerView = [[ADBannerView alloc] initWithFrame:frame];
    // Set the delegate to self, so that we are notified of ad responses.
    bannerView.delegate = self;
    // Set the autoresizing mask so that the banner is pinned to the bottom
    bannerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
    // Since we support all orientations in this view controller, support portrait and landscape content sizes.
    // If you only supported landscape or portrait, you could remove the other from this set.
    
	bannerView.requiredContentSizeIdentifiers = (&ADBannerContentSizeIdentifierPortrait != nil) ?
	[NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil] : 
	[NSSet setWithObjects:ADBannerContentSizeIdentifier320x50, ADBannerContentSizeIdentifier480x32, nil];
	
    // At this point the ad banner is now be visible and looking for an ad.
    self.banner = bannerView;
	[bannerView release];
}

-(void)layoutForCurrentOrientation:(BOOL)animated
{
    CGFloat animationDuration = animated ? 0.2f : 0.0f;
    // by default content consumes the entire view area
    CGRect contentFrame = self.view.bounds;
    // the banner still needs to be adjusted further, but this is a reasonable starting point
    // the y value will need to be adjusted by the banner height to get the final position
	CGPoint bannerOrigin = CGPointMake(CGRectGetMinX(contentFrame), CGRectGetMinY(contentFrame));
    CGFloat bannerHeight = 0.0f;
    
    // First, setup the banner's content size and adjustment based on the current orientation
    if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		banner.currentContentSizeIdentifier = (&ADBannerContentSizeIdentifierLandscape != nil) ? ADBannerContentSizeIdentifierLandscape : ADBannerContentSizeIdentifier480x32;
    else
        banner.currentContentSizeIdentifier = (&ADBannerContentSizeIdentifierPortrait != nil) ? ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifier320x50; 
    bannerHeight = banner.bounds.size.height; 
	
    // Depending on if the banner has been loaded, we adjust the content frame and banner location
    // to accomodate the ad being on or off screen.
    if(banner.bannerLoaded)
    {
        contentFrame.size.height -= bannerHeight;
		contentFrame.origin.y += bannerHeight;
    }
    	
    
	UIView* view = self.imageView;
    // And finally animate the changes, running layout for the content view if required.
	    [UIView animateWithDuration:animationDuration
	                     animations:^{
	                         view.frame = contentFrame;
	                         [view layoutIfNeeded];
	                         banner.frame = CGRectMake(bannerOrigin.x, bannerOrigin.y, banner.frame.size.width, banner.frame.size.height);
	                     }];
}


-(void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self layoutForCurrentOrientation:YES];
}

-(void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self layoutForCurrentOrientation:YES];
}

-(BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    return YES;
}

-(void)bannerViewActionDidFinish:(ADBannerView *)banner
{
}

@end