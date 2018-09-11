//
//  MPWUniquingQueue.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/10/18.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWUniquingQueue : MPWFilter

@property (readonly)  NSUInteger count;

-(void)forwardNext;
-(void)drain;



@end
