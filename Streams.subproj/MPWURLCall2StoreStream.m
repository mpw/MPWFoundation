//
//  MPWURLCall2StoreStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/29/18.
//

#import "MPWURLCall2StoreStream.h"
#import "MPWURLCall.h"
#import "MPWDictStore.h"

@implementation MPWURLCall2StoreStream

-(void)writeObject:(MPWURLCall*)aCall
{
    [self.store mergeObject:aCall.processedObject forReference:aCall.reference];
}

@end

#import "DebugMacros.h"

@implementation MPWURLCall2StoreStream(testing)


+(void)testCallsObjectEndsUpInStore
{
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:@"hi"];
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
