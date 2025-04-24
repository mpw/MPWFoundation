//
//  MPWLockedFilter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 24.04.25.
//

#import "MPWLockedFilter.h"

@interface MPWLockedFilter()

@property (nonatomic, strong) NSLock *lock;

@end

@implementation MPWLockedFilter

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    self.lock = [[[NSLock alloc] init] autorelease]; 
    return self;
}

-(void)writeObject:(id)anObject
{
    [self.lock lock];
    FORWARD( anObject );
    [self.lock unlock];
}

-(void)dealloc
{
    [_lock release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWLockedFilter(testing) 

+(void)testBasicForwarding
{
    MPWLockedFilter *f=[self stream];
    EXPECTNIL([f.target firstObject],@"target empty");
    [f writeObject:@"bozo"];
    IDEXPECT([f.target firstObject],@"bozo",@"did write");
}

+(NSArray*)testSelectors
{
   return @[
			@"testBasicForwarding",
			];
}

@end
