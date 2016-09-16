//
//  MPWNotificationStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 26/08/2016.
//
//

#import "MPWNotificationStream.h"

@interface MPWNotificationStream ()

@property (nonatomic, strong) NSString *notificationName;
@property (nonatomic, assign) BOOL     shouldPostOnMainThread;

@end


@implementation MPWNotificationStream

+(instancetype)streamWithNotificationName:(NSString *)name
{
    
}


-(void)postNotificationObject:anObject
{
    [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationName
                                                        object:anObject];
}

-(void)writeObject:anObject
{
    if ( self.shouldPostOnMainThread) {
        [[self onMainThread] postNotificationObject:anObject];
    } else {
        [self postNotificationObject:anObject];
    }
    [super writeObject:anObject];
}

@end
