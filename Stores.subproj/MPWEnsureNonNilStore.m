//
//  MPWEnsureNonNilStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 29.12.23.
//

#import "MPWEnsureNonNilStore.h"
@implementation MPWEnsureNonNilStore

-(id)mapRetrievedObject:(id)anObject forReference:(id<MPWReferencing>)aReference
{
    if (anObject == nil ) {
        @throw [NSException exceptionWithName:@"nilnotallowed" reason:@"object was nil but should not have been" userInfo:@{
            @"ref": aReference,
            @"store" : self.source
        }];
    }
    return anObject;
}

@end




#import <MPWFoundation/DebugMacros.h>
#import "MPWDictStore.h"

@implementation MPWEnsureNonNilStore(testing)

+(void)testNilResultRaises
{
    MPWDictStore *base=[[[MPWDictStore alloc] initWithDictionary:[[@{ @"a": @(20) } mutableCopy] autorelease]] autorelease];
    MPWEnsureNonNilStore *store=[MPWEnsureNonNilStore storeWithSource:base];
    id dummy=nil;
    @try {
        dummy=store[@"b"];
        @throw [NSException exceptionWithName:@"didntraise" reason:@"should have raised" userInfo:nil];
    } @catch (NSException*  exception){
        IDEXPECT(exception.name,@"nilnotallowed",@"not the exception we wanted");
    }
    EXPECTNIL(dummy,@"should still be nil");
}

+(NSArray*)testSelectors
{
   return @[
			@"testNilResultRaises",
			];
}

@end
