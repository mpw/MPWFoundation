//
//  MPWEnsureNonNilStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 29.12.23.
//

#import "MPWEnsureNonNilStore.h"
@implementation MPWEnsureNonNilStore

-(id)mapRetrievedObject:(id)anObject forReference:(id<MPWIdentifying>)aReference
{
    if (anObject == nil ) {
        NSString *reason=[NSString stringWithFormat:@"%@ was nil but should not have been",[aReference path]];
        @throw [NSException exceptionWithName:@"nilnotallowed" reason:reason userInfo:@{
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

+(instancetype)_testStore
{
    MPWDictStore *base=[[[MPWDictStore alloc] initWithDictionary:[[@{ @"a": @(20) } mutableCopy] autorelease]] autorelease];
    return [MPWEnsureNonNilStore storeWithSource:base];
}

+(void)testNilResultRaises
{
    MPWEnsureNonNilStore *store=[self _testStore];;
    id dummy=nil;
    @try {
        dummy=store[@"b"];
        @throw [NSException exceptionWithName:@"didntraise" reason:@"should have raised" userInfo:nil];
    } @catch (NSException*  exception){
        IDEXPECT(exception.name,@"nilnotallowed",@"not the exception we wanted");
    }
    EXPECTNIL(dummy,@"should still be nil");
}

+(void)testNonNilResultDoesNotRaise
{
    IDEXPECT( [self _testStore][@"a"],@(20),@"value that exists should just be retrieved");
}

+(NSArray*)testSelectors
{
   return @[
       @"testNilResultRaises",
       @"testNonNilResultDoesNotRaise",
			];
}

@end
