
#import "PhotoProcessViewController.h"
#import <opencv/cv.h>
#import "MyUIBox.h"
#import "MyImageKit.h"
#import "Appirater.h"
#import "SHK.h"
#import "EffectsTableViewController.h"

static NSString* message = @"More fun apps from us: http://DesignForApple.com, follow us with twitter.com/design4apple, email us with design4apple@gmail.com,thanks for your feedbacks in advance!";
static NSString* title = @"Sepia Pro App from DesignForApple.com";

#define TOOLBAR_HEIGHT 60 
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



@implementation PhotoProcessViewController

@synthesize imageView = _imageView;
@synthesize slider1 = _slider1 ,slider2;
@synthesize toolbar = _toolbar;
@synthesize picker = _picker;
@synthesize popover = _popover;
@synthesize activity = _activity;
@synthesize beforeImage = _beforeImage;
@synthesize currentType;


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

CGImageRef createStandardImage(CGImageRef image) {
	const size_t width = CGImageGetWidth(image);
	const size_t height = CGImageGetHeight(image);
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, space,
											 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(space);
	CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), image);
	CGImageRef dstImage = CGBitmapContextCreateImage(ctx);
	CGContextRelease(ctx);
	return dstImage;
}

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

- (NSString*) effectName:(EffectType)effectType
{
	NSString* name = nil;
	switch (effectType) {
		case -1:
			name = @"No Effect";
			break;
		case Sepia:
			name = @"Sepia";
			break;
		case OilPaint:
			name = @"Oil Painting";
			break;
		default:
			name=@"unknown";
			break;
	}
	return name;
}

-(MagickBooleanType) filterOilPainting:(MagickWand*)magick_wand{
	MagickBooleanType status;
	
	float ratio1 = self.slider1.value/20;
	//float ratio2 = slider2.value;
	
	status = MagickOilPaintImage(magick_wand,ratio1);  //2
	status = MagickRadialBlurImage(magick_wand,1);  // 1
	return status;
}

-(MagickBooleanType) filterSepiaTone:(MagickWand*)magick_wand{
	float ratio1 = self.slider1.value*1.5 + 80;
	return MagickSepiaToneImage(magick_wand,
								ratio1 );
}

-(MagickBooleanType) filterSpread:(MagickWand*)magick_wand{
	float ratio = self.slider1.value*0.3; // (0, 10.0)
	return MagickSpreadImage(magick_wand,ratio /*const double radius*/);
}


-(void) filterWave:(MagickWand*)magick_wand{
	MagickBooleanType status;
	float ratio1 = self.slider1.value*0.1; // (0, 10.0)
	float ratio2 = self.slider2.value+80;

	//bool MagickWaveImage( MagickWand mgck_wnd, float amplitude, float wave_length )
	status = MagickWaveImage(magick_wand,ratio1,ratio2 /*const double radius*/);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
}

-(void) filterRadialBlur:(MagickWand*)magick_wand{
	MagickBooleanType status;
	float ratio = self.slider1.value*0.2; // (0, 20.0)
	
	status = MagickRadialBlurImage(magick_wand,ratio /*const double radius*/);
	
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
}

-(void) filterNegate:(MagickWand*)magick_wand{
	MagickBooleanType status;
	//TRUE no meaning 
	status = MagickNegateImage(magick_wand,FALSE /*const double radius*/);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
}

-(void) filterSolarize:(MagickWand*)magick_wand{
	MagickBooleanType status;
	float ratio = self.slider1.value*2.55; // (0, 255)
	
	status =MagickRadialBlurImage(magick_wand,
								  1.0 );
	status = MagickSolarizeImage(magick_wand,ratio /*const double radius*/);
	
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
}
// long time 
-(void) filterCharcoal:(MagickWand*)magick_wand{
	MagickBooleanType status;
	float ratio1 = self.slider1.value*0.05; // (0, 5.0)
	float ratio2 = self.slider2.value*0.1;
	NSLog(@"ratio1 %f ratio2 %f ",ratio1,ratio2);
	
	//status =MagickRadialBlurImage(magick_wand,
	//							  1.0 );
	status = MagickBlurImage(magick_wand, 3.0, 3.0);
		
	status = MagickCharcoalImage(magick_wand,ratio1,ratio2 /*const double radius*/);
	
	status = MagickContrastImage(magick_wand,TRUE);

	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
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
	CGImageRef standardized = createStandardImage(srcCGImage);
	NSData *srcData1 = (NSData *) CGDataProviderCopyData(CGImageGetDataProvider(standardized));
	CGImageRelease(standardized);
	const void *bytes = [srcData1 bytes];
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
		default:
			break;
	}
		//[self filterSpread:magick_wand_local];
	//[self filterWave:magick_wand_local];
	//[self filterRadialBlur:magick_wand_local];
	//[self filterNegate: magick_wand_local];
	//[self filterSolarize: magick_wand_local];
	//[self filterCharcoal:magick_wand_local];
	//[self filterFuzz:magick_wand_local];
	
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
	CGImageRelease(cgimage);
	CGContextRelease(context);
	[srcData1 release];
	free(trgt_image);
	
	[self.imageView	performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
	
	[self performSelectorOnMainThread:@selector(hideProgressIndicator) withObject:nil waitUntilDone:TRUE];
	
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
	//[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.view.userInteractionEnabled = TRUE;
	[self.activity hide];
	AudioServicesPlaySystemSound(alertSoundID);
	
}



#pragma mark -
#pragma mark UIViewControllerDelegate

- (void)viewDidLoad {
	[super viewDidLoad];

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Tink" ofType:@"aiff"] isDirectory:NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url, &alertSoundID);
	
	[self.view addSubview:self.imageView];
	[self.view addSubview:self.slider1];
	[self.view addSubview:self.slider2];
	[self.view addSubview:self.toolbar];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation == UIInterfaceOrientationPortrait || 
				interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	if (touches.count > 0) {
		//if (needSlider1) {
			self.slider1.hidden = !self.slider1.hidden;
		//}
		if (needSlider2) {
			self.slider2.hidden = !self.slider2.hidden;
		}
		_toolbar.hidden = !_toolbar.hidden;
	}
}

-(void)adjustEffect:(id)sender{
	if(self.imageView.image){
		[self showProgressIndicator:[self effectName:currentType]];
		[self performSelectorInBackground:@selector(doFiltering:) withObject:self.beforeImage];
	}
}

#pragma mark 
#pragma mark property 

//- (CGImageRef) beforeImage
//{
//	return _beforeImage;
//}

- (LabeledActivityIndicatorView*) activity
{
	if (!_activity) {
		_activity = [[LabeledActivityIndicatorView alloc] initWithController:self andText:@"Rendering..."];
	}
	return _activity;
}
- (UIToolbar*) toolbar
{
	if (!_toolbar) {
		_toolbar = [[UIToolbar alloc] init ];
		CGRect fullRect = [UIScreen mainScreen].applicationFrame;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			
			UIBarButtonItem *loadItem = [[UIBarButtonItem alloc] initWithTitle:@"Load Photo" style:UIBarButtonItemStyleBordered 																			  target:self 
													   action:@selector(loadImage:)];
			UIBarButtonItem *emailItem = [[UIBarButtonItem alloc] initWithTitle:@"Write Email to Us" style:UIBarButtonItemStyleBordered 																			  target:self 
																		 action:@selector(pickupEffect:)];
			
			UIBarButtonItem *reviewItem = [[UIBarButtonItem alloc] initWithTitle:@"Rate Me" style:UIBarButtonItemStyleBordered 																			  target:self 
																		  action:@selector(rateMe:)];
			
			UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"Share to Friends" style:UIBarButtonItemStyleBordered																			  target:self 
																		action:@selector(shareImage:)];
			
			
			// Create a space item and set it and the search bar as the items for the toolbar.
			UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
			_toolbar.items = [NSArray arrayWithObjects:loadItem,spaceItem, emailItem,spaceItem,reviewItem,spaceItem, saveItem, nil];
			_toolbar.frame = CGRectMake(0, fullRect.size.height - TOOLBAR_HEIGHT, fullRect.size.width,  TOOLBAR_HEIGHT);
			
			_toolbar.barStyle = UIBarStyleBlackTranslucent;
			_toolbar.alpha = 0.8f;
			
			[spaceItem release];
			[saveItem release];
			[emailItem release];
			[reviewItem release];
			
		} else {
			UIBarButtonItem *loadItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
																	 target:self action:@selector(loadImage:)];
			
			UIBarButtonItem *effectsPickr = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
																						  target:self action:@selector(pickupEffect:)];
			
			UIBarButtonItem *reviewItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																						target:self action:@selector(rateMe:)];
			
			UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStyleBordered																			  target:self 
																		action:@selector(shareImage:)];			
			// Create a space item and set it and the search bar as the items for the toolbar.
			UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
			_toolbar.items = [NSArray arrayWithObjects:loadItem,spaceItem, effectsPickr,spaceItem, reviewItem, spaceItem,saveItem,spaceItem, nil];
			
			_toolbar.frame = CGRectMake(0, fullRect.size.height - TOOLBAR_HEIGHT, fullRect.size.width,  TOOLBAR_HEIGHT);
			
			_toolbar.barStyle = UIBarStyleBlackTranslucent;
			_toolbar.alpha = 0.8f;
			[spaceItem release];
			[saveItem release];
			[effectsPickr release];
			[reviewItem release];
		}		
	}
	
	return _toolbar;
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
		UIImage *defaultImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"jobs" ofType:@"png"]];
		_imageView = [[UIImageView alloc]initWithFrame:fullRect];
		_imageView.image = defaultImage;
		self.beforeImage = createStandardImage(_imageView.image.CGImage); 
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
				self.beforeImage = createStandardImage(self.imageView.image.CGImage);				
			} 
			if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
				self.picker.sourceType = sourceType;
				[self presentModalViewController:self.picker animated:YES];
			}
}
#pragma mark -
#pragma mark IBAction

- (void) resetData
{
	currentType = -1;  // no selected effects 
	[self.slider1 setValue:SLIDER_DEFAULT];
}

- (IBAction)loadImage:(id)sender {
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		NSLog(@"iPad");
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

- (IBAction)rateMe:(id)sender {
	[Appirater userDidSignificantEvent:YES];
}


-(IBAction)pickupEffect:(id)sender{
	
	EffectsTableViewController	*etvc = [[EffectsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
	etvc.delegate = self;
	etvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:etvc animated:YES];
	[etvc release];
}



- (void)mailComposeController:(MFMailComposeViewController*)controller  
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError*)error;
{
	if (result == MFMailComposeResultSent) {
		NSLog(@"It's away!");
	}
	[self dismissModalViewControllerAnimated:YES];
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
	self.currentType = type;
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
	self.beforeImage = createStandardImage(selectedImage.CGImage);
	self.imageView.image = [MyImageKit scaleAndRotateImage:selectedImage];
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}
@end