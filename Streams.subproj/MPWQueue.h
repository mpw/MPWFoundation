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
@property (readonly) BOOL isAsynchronous;

+(instancetype)queueWithTarget:(id)aTarget uniquing:(BOOL)shouldUnique;
-(instancetype)initWithTarget:(id)aTarget uniquing:(BOOL)shouldUnique;


-(void)forwardSingleObject;
-(void)triggerDrain;
-(void)makeAsynchronous;


@end
