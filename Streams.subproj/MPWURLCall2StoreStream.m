//
//  MPWURLCall2StoreStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/29/18.
//

#import "MPWURLCall2StoreStream.h"
#import "MPWURLCall.h"
#import "MPWDictStore.h"
#import "MPWGenericIdentifier.h"
#import "MPWRESTOperation.h"
#import <AccessorMacros.h>

@implementation MPWURLCall2StoreStream

-(instancetype)initWithStore:(NSObject <MPWStorage>*)newStore
{
    self=[super init];
    self.store=newStore;
    return self;
}

-(void)writeObject:(MPWURLCall*)aCall sender:aSender
{
    [self.store merge:aCall.processedObject at:aCall.reference];
}

-(void)dealloc
{
    [_store release];
    [super dealloc];
}

@end

#import "DebugMacros.h"

@implementation MPWURLCall2StoreStream(testing)


+(void)testCallsObjectEndsUpInStore
{
    MPWGenericIdentifier *ref=[MPWGenericIdentifier referenceWithPath:@"hi"];
    MPWDictStore *store=[MPWDictStore store];
    MPWURLCall2StoreStream *s=[self stream];
    s.store=store;
    MPWURLCall *call=[MPWURLCall callWithRESTOperation:[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbGET]];
    NSString *testpayload=@"Hello World";
    call.processedObject=testpayload;
    EXPECTNIL( store[ref],@"before");
    [s writeObject:call];
    IDEXPECT( store[ref], testpayload, @"stored" );
    
}

+testSelectors
{
    return @[
             @"testCallsObjectEndsUpInStore",
             ];
}


@end
