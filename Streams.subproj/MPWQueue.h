//
//  MPWUniquingQueue.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/10/18.
//

#import <MPWFoundation/MPWFoundation.h>

@interface MPWQueue : MPWFilter

@property (readonly)  NSUInteger count;
@property (atomic, assign) BOOL removeInflight;
@property (atomic, assign) BOOL autoFlush;


-(void)forwardSingleObject;
-(void)drain;



@end
