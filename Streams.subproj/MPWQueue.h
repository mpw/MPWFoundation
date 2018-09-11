//
//  MPWUniquingQueue.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/10/18.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWQueue : MPWFilter

@property (readonly)  NSUInteger count;

-(void)forwardNext;
-(void)drain;



@end
