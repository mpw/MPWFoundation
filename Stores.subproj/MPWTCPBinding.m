//
//  MPWTCPBinding.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 15.02.23.
//

#import "MPWTCPBinding.h"

@interface MPWTCPBinding()

@property (nonatomic,assign) int port;

@end

@implementation MPWTCPBinding

-(instancetype)initWithReference:aReference inStore:aStore
{
    self=[super initWithReference:aReference inStore:aStore];
    self.port = [[aReference stringValue] intValue];
    return self;
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTCPBinding(testing) 

+(void)testHasPort
{
    MPWTCPBinding *binding = [self bindingWithReference:@"80" inStore:nil];
    INTEXPECT( binding.port, 80, @"port");
}

+(NSArray*)testSelectors
{
   return @[
       @"testHasPort",
			];
}

@end
