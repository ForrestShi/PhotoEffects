//
//  MyUIBox.h
//  OilPainting
//
//  Created by forrest on 10-11-6.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MyUIBox : NSObject {

}

+(UISlider*)yellowSlider:(CGRect)rect withMax:(float)fMax withMin:(float)fMin withValue:(float)fValue withLabel:(NSString*)label;

@end
