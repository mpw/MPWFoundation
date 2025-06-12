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

-(instancetype)initWithIdentifier:(id)anIdentifier inStore:(id)aStore
{
    self=[super initWithIdentifier:anIdentifier inStore:aStore];
    self.port = [[anIdentifier stringValue] intValue];
    return self;
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTCPBinding(testing) 

+(void)testHasPort
{
    MPWTCPBinding *binding = [self referenceWithIdentifier:@"80" inStore:nil];
    INTEXPECT( binding.port, 80, @"port");
}

+(NSArray*)testSelectors
{
   return @[
       @"testHasPort",
			];
}

@end
