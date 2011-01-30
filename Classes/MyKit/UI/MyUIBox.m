//
//  MyUIBox.m
//  OilPainting
//
//  Created by forrest on 10-11-6.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MyUIBox.h"

#define kSliderHeight			7.0
#define SLIDER_MAX 6;
#define SLIDER_MIN 0;
#define SLIDER_VALUE_DEFAULT 3;

@implementation MyUIBox

// [customSlider addTarget:self action:myAction forControlEvents:UIControlEventValueChanged];

+(UISlider*)yellowSlider:(CGRect)rect withMax:(float)fMax withMin:(float)fMin 
			   withValue:(float)fValue withLabel:(NSString*)label{
	
	CGRect frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, kSliderHeight);
	UISlider*  customSlider = [[[UISlider alloc] initWithFrame:frame] autorelease];
	
	// in case the parent view draws with a custom color or gradient, use a transparent color
	customSlider.backgroundColor = [UIColor clearColor];	
	UIImage *stetchLeftTrack = [[UIImage imageNamed:@"orangeslide.png"]
								stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
	UIImage *stetchRightTrack = [[UIImage imageNamed:@"yellowslide.png"]
								 stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
	[customSlider setThumbImage: [UIImage imageNamed:@"slider_ball.png"] forState:UIControlStateNormal];
	[customSlider setMinimumTrackImage:stetchLeftTrack forState:UIControlStateNormal];
	[customSlider setMaximumTrackImage:stetchRightTrack forState:UIControlStateNormal];
	customSlider.minimumValue = fMin;
	customSlider.maximumValue = fMax;
	customSlider.continuous = NO;
	customSlider.value = fValue;
	
	// Add an accessibility label that describes the slider.
	//[customSlider setAccessibilityLabel:NSLocalizedString(@"CustomSlider", label)];
	customSlider.accessibilityLabel = label;
    return customSlider;
	
}
@end
