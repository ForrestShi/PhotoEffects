
//


#import "PhotoProcessViewController.h"
#import <opencv/cv.h>
#import "MyUIBox.h"
#import "MyImageKit.h"
#import "Appirater.h"
#import "SHK.h"

static NSString* message = @"More fun apps from us: http://DesignForApple.com, follow us with twitter.com/design4apple, email us with design4apple@gmail.com,thanks for your feedbacks in advance!";
//static NSString* title = @"Swirl your friends' faces with fun !";
static NSString* title = @"Sepia Pro App from DesignForApple.com";


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

@synthesize imageView;
@synthesize slider1,blurAdjustSlider;
@synthesize toolbar,loadItem;
@synthesize picker = _picker;
@synthesize popover = _popover;
@synthesize activity;
@synthesize oriCGImage;


- (void)dealloc {
	AudioServicesDisposeSystemSoundID(alertSoundID);

	CGImageRelease(oriCGImage);
	[imageView release];
	[activity  release];
	[slider1 release]; 
	[blurAdjustSlider release];
	[toolbar release];
	[loadItem release];
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




-(void) filterOilPainting:(MagickWand*)magick_wand{

	MagickBooleanType status;
	
	float ratio1 = slider1.value;
	float ratio2 = blurAdjustSlider.value;
	
	status = MagickOilPaintImage(magick_wand,ratio1);  //2
	status =MagickRadialBlurImage(magick_wand,
								  ratio2);  // 1
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
}

-(void) filterSepiaTone:(MagickWand*)magick_wand{
	MagickBooleanType status;
	float ratio1 = slider1.value*1.5 + 80;
	status =MagickSepiaToneImage(magick_wand,
								 ratio1 );
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
}

-(void) filterSpread:(MagickWand*)magick_wand{
	MagickBooleanType status;
	float ratio = slider1.value*0.3; // (0, 10.0)
 
	status = MagickSpreadImage(magick_wand,ratio /*const double radius*/);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
}


-(void) filterWave:(MagickWand*)magick_wand{
	MagickBooleanType status;
	float ratio1 = slider1.value*0.1; // (0, 10.0)
	float ratio2 = blurAdjustSlider.value+80;

	//bool MagickWaveImage( MagickWand mgck_wnd, float amplitude, float wave_length )
	status = MagickWaveImage(magick_wand,ratio1,ratio2 /*const double radius*/);
	if (status == MagickFalse) {
		ThrowWandException(magick_wand);
	}
}

-(void) filterRadialBlur:(MagickWand*)magick_wand{
	MagickBooleanType status;
	float ratio = slider1.value*0.2; // (0, 20.0)
	
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
	float ratio = slider1.value*2.55; // (0, 255)
	
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
	float ratio1 = slider1.value*0.05; // (0, 5.0)
	float ratio2 = blurAdjustSlider.value*0.1;
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


	[self filterSepiaTone:magick_wand_local];
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
	
	[imageView	performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:YES];
	
	[self performSelectorOnMainThread:@selector(hideProgressIndicator) withObject:nil waitUntilDone:TRUE];
	
	[pool drain];
}


#pragma mark -
#pragma mark Utilities for intarnal use

- (void)showProgressIndicator:(NSString *)text {
	
	self.view.userInteractionEnabled = FALSE;
	[activity show];
}

- (void)hideProgressIndicator {
	//[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.view.userInteractionEnabled = TRUE;
	[activity hide];
	AudioServicesPlaySystemSound(alertSoundID);
	
}



#pragma mark -
#pragma mark UIViewControllerDelegate

- (void)viewDidLoad {
	[super viewDidLoad];

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];

	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Tink" ofType:@"aiff"] isDirectory:NO];
	AudioServicesCreateSystemSoundID((CFURLRef)url, &alertSoundID);

	CGRect fullRect = [UIScreen mainScreen].applicationFrame;
	
	
	UIImage *defaultImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"jobs" ofType:@"png"]];
	imageView = [[UIImageView alloc]initWithFrame:fullRect];//[[UIImageView alloc]initWithImage:defaultImage];
	imageView.image = defaultImage;
	oriCGImage =  createStandardImage(imageView.image.CGImage);

	
	self.activity = [[LabeledActivityIndicatorView alloc] initWithController:self andText:@"Rendering..."];
    
	[self.view addSubview:imageView];
	
	const float gapHeight = 45.0f;
	
	CGRect slider = CGRectMake(fullRect.size.width/10, fullRect.size.height*0.8, fullRect.size.width*0.8, 10);
	slider1 = [MyUIBox yellowSlider:slider withMax:100 withMin:0 withValue:50 withLabel:@"brush size"];
	slider.origin.y += gapHeight;
	[slider1 addTarget:self action:@selector(adjustEffect:) forControlEvents:UIControlEventValueChanged];

	blurAdjustSlider = [MyUIBox yellowSlider:slider withMax:100 withMin:0 withValue:50 withLabel:@"smooth"];
	//[blurAdjustSlider addTarget:self action:@selector(adjustEffect:) forControlEvents:UIControlEventValueChanged];
	
	[self.view addSubview:slider1];
	//[self.view addSubview:blurAdjustSlider];
	
	_picker = [[UIImagePickerController alloc] init];
	_picker.delegate = self;

	//tool bar
	toolbar = [[UIToolbar alloc]init];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        
		loadItem = [[UIBarButtonItem alloc] initWithTitle:@"Load Photo" style:UIBarButtonItemStyleBordered 																			  target:self 
												   action:@selector(loadImage:)];
		UIBarButtonItem *emailItem = [[UIBarButtonItem alloc] initWithTitle:@"Write Email to Us" style:UIBarButtonItemStyleBordered 																			  target:self 
																	 action:@selector(emailUs:)];
		
		UIBarButtonItem *reviewItem = [[UIBarButtonItem alloc] initWithTitle:@"Rate Me" style:UIBarButtonItemStyleBordered 																			  target:self 
																	 action:@selector(rateMe:)];
		
		UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"Share to Friends" style:UIBarButtonItemStyleBordered																			  target:self 
																	action:@selector(shareImage:)];
		
		
		// Create a space item and set it and the search bar as the items for the toolbar.
		UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
		toolbar.items = [NSArray arrayWithObjects:loadItem,spaceItem, emailItem,spaceItem,reviewItem,spaceItem, saveItem, nil];
		toolbar.frame = CGRectMake(0, 0, fullRect.size.width, 60);
		
		toolbar.barStyle = UIBarStyleBlackTranslucent;
		toolbar.alpha = 0.8f;

		[self.view addSubview:toolbar];
		
		[spaceItem release];
		[saveItem release];
		[emailItem release];
		[reviewItem release];
		
		_popover = [[UIPopoverController alloc] initWithContentViewController:_picker];
		[_popover setDelegate:self];
		
	} else {
		NSLog(@"iPhone ");
		
		loadItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
																 target:self action:@selector(loadImage:)];
		
		UIBarButtonItem *emailItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
																target:self action:@selector(emailUs:)];

		UIBarButtonItem *reviewItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																				   target:self action:@selector(rateMe:)];
		
		UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStyleBordered																			  target:self 
																	action:@selector(shareImage:)];
		
		
		// Create a space item and set it and the search bar as the items for the toolbar.
		UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
		toolbar.items = [NSArray arrayWithObjects:loadItem,spaceItem, emailItem,spaceItem, reviewItem, spaceItem,saveItem,spaceItem, nil];
		
		toolbar.frame = CGRectMake(0, 0, fullRect.size.width, 40);

		toolbar.barStyle = UIBarStyleBlackTranslucent;
		toolbar.alpha = 0.8f;
		
		[self.view addSubview:toolbar];
		
		[spaceItem release];
		[saveItem release];
		[emailItem release];
		[reviewItem release];
		
		[self loadImage:nil];
    }
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation == UIInterfaceOrientationPortrait || 
				interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
	if (touches.count > 0) {
		//blurAdjustSlider.hidden = !blurAdjustSlider.hidden;
		slider1.hidden = !slider1.hidden;
		toolbar.hidden = !toolbar.hidden;
	}
}

-(void)adjustEffect:(id)sender{
	if(imageView.image){
		[self showProgressIndicator:@"working"];
		[self performSelectorInBackground:@selector(doFiltering:) withObject:oriCGImage];
	}
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
				imageView.image = [UIImage imageWithContentsOfFile:path];
				oriCGImage =  createStandardImage(imageView.image.CGImage);				
			} 
			if([UIImagePickerController isSourceTypeAvailable:sourceType]) {
				_picker.sourceType = sourceType;
				[self presentModalViewController:_picker animated:YES];
			}
}
#pragma mark -
#pragma mark IBAction

- (IBAction)loadImage:(id)sender {
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		NSLog(@"iPad");
		[self showPhotoLibrary];
	}else {
		UIActionSheet *actionSheet;
		
		actionSheet = [[UIActionSheet alloc] initWithTitle:@"Load Photo"
												  delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
										 otherButtonTitles:@"From Photo Album", @"Take Photo With Camera",@"Fat Jobs", nil];
		actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
		[actionSheet showInView: self.imageView ];
		[actionSheet release];
	}
	//reset with new selected image
	
	
}

- (IBAction)shareImage:(id)sender {
	if(imageView.image) {
		
		if (_popover) {
			[_popover dismissPopoverAnimated:YES];
		}
		SHKItem *item = [SHKItem image:imageView.image title:title];
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


-(void)emailUs:(id)sender{
	MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
	controller.mailComposeDelegate = self;
	[controller setSubject:title];
	[controller setMessageBody:message isHTML:NO]; 
	[controller setToRecipients:[NSArray arrayWithObjects:@"design4app@gmail.com",nil]];
	[self presentModalViewController:controller animated:YES];
	[controller release];
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

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

-(void) showPhotoLibrary
{	
	if (loadItem != nil) {
		[_popover presentPopoverFromBarButtonItem:loadItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
	
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
	UIImage* selectedImage = [info	objectForKey:@"UIImagePickerControllerOriginalImage"];
	imageView.image = [MyImageKit scaleAndRotateImage:selectedImage];
	
	//[self resetWand];
	self.oriCGImage = createStandardImage(imageView.image.CGImage);
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	NSLog(@"%s",__FUNCTION__);
	[[picker parentViewController] dismissModalViewControllerAnimated:YES];
}
@end