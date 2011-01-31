//
//  EffectsTableViewController.h
//  ABCPhotoEffects
//
//  Created by forrest on 11-1-30.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FlipbackDelegate;


@interface EffectsTableViewController : UITableViewController {
	NSMutableArray	*_effectsArray;
	id<FlipbackDelegate> delegate;
}

@property(retain) NSMutableArray	*effectsArray;
@property(retain) id<FlipbackDelegate> delegate;
@end
