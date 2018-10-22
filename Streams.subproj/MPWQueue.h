//
//  MPWUniquingQueue.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/10/18.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWQueue : MPWFilter

@property (readonly)  NSUInteger count;
@property (assign)    BOOL       removeInflight;
-(void)forwardNext;
-(void)drain;



@end
