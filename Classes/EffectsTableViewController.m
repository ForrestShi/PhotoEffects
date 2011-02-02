//
//  EffectsTableViewController.m
//  ABCPhotoEffects
//
//  Created by forrest on 11-1-30.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EffectsTableViewController.h"


@implementation EffectsTableViewController

@synthesize effectsArray = _effectsArray;
@synthesize delegate;

#pragma mark -
#pragma mark Initialization



- (void)dealloc {
	[_effectsArray release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
    }
    return self;
}



#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.title = @"Choose A Effect";
	
	if (!_effectsArray) {
		NSString *path = [[NSBundle mainBundle] pathForResource:@"effects" ofType:@"plist"];
		NSMutableArray *array = [[NSMutableArray alloc] initWithContentsOfFile:path];
		self.effectsArray = array;
		[array release];		
	}
}



/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [_effectsArray  count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
	id effect = [_effectsArray objectAtIndex:indexPath.row];
	if (effect) {
		cell.textLabel.text = [effect valueForKey:@"name"];
		UIImage* previewImg = [UIImage imageNamed:[effect valueForKey:@"preview"]];//[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[[effect valueForKey:@"name"]] ofType:@"png"];
		
		//cell.imageView.frame = CGRectMake(30, 30, 128, 128);
		cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
		cell.imageView.bounds = CGRectMake(0, 0, 128, 128);
		cell.imageView.autoresizingMask =  ( UIViewAutoresizingFlexibleWidth || UIViewAutoresizingFlexibleHeight );
		cell.imageView.image =previewImg;
		cell.detailTextLabel.text = [effect valueForKey:@"detail"];
		cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
	
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.

	if ([delegate respondsToSelector:@selector(flipback:)]) {
		[delegate performSelector:@selector(flipback:) withObject:indexPath.row];
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


@end

