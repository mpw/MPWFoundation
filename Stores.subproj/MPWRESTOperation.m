//
//  MPWRESTOperation.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/3/18.
//

#import "MPWRESTOperation.h"
#import <AccessorMacros.h>
#import <MPWAbstractStore.h>

@implementation MPWRESTOperation

CONVENIENCEANDINIT( operation, WithReference:(id <MPWReferencing>)reference verb:(MPWRESTVerb)verb)
{
    self=[super init];
    self.reference=reference;
    self.verb=verb;
    return self;
}

+(NSString*)HTTPVerb:(MPWRESTVerb)verb
{
    switch ( verb ) {
        case MPWRESTVerbGET:
            return @"GET";
        case MPWRESTVerbPUT:
            return @"PUT";
        case MPWRESTVerbPATCH:
            return @"PATCH";
        case MPWRESTVerbDELETE:
            return @"DELETE";
        case MPWRESTVerbPOST:
            return @"POST";
        default:
            return nil;
    }
}

-(NSString*)HTTPVerb
{
    return [[self class] HTTPVerb:self.verb];
}


-(void)dealloc
{
    [(NSObject*)_reference release];
    [super dealloc];
}

@end

#import "DebugMacros.h"

@implementation MPWRESTOperation(testing)

+(void)testHTTPVerb
{
    IDEXPECT( [[self operationWithReference:nil verb:MPWRESTVerbGET] HTTPVerb], @"GET", @"GET");
    IDEXPECT( [[self operationWithReference:nil verb:MPWRESTVerbPUT] HTTPVerb], @"PUT", @"PUT");
    IDEXPECT( [[self operationWithReference:nil verb:MPWRESTVerbDELETE] HTTPVerb], @"DELETE", @"DELETE");
    IDEXPECT( [[self operationWithReference:nil verb:MPWRESTVerbPATCH] HTTPVerb], @"PATCH", @"PATCH");
}

+testSelectors
{
    return @[
             @"testHTTPVerb",
             ];
}

@end
