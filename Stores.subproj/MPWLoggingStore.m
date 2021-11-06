//
//  MPWLoggingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/3/18.
//

#import "MPWLoggingStore.h"
#import "MPWGenericReference.h"
#import <AccessorMacros.h>
#import "MPWRESTOperation.h"
#import <MPWByteStream.h>

@implementation MPWLoggingStore

CONVENIENCEANDINIT( store , WithSource:(NSObject <MPWStorage,MPWHierarchicalStorage>*)aSource loggingTo:(id <Streaming>)log )
{
    self=[super initWithSource:aSource];
    self.log=(NSObject <Streaming>*)log;
    return self;
}

-(void)at:(id<MPWReferencing>)aReference put:anObject
{
    [super at:aReference put:anObject];
    [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPUT]];
}

-(void)merge:anObject at:(id<MPWReferencing>)aReference
{
    [super merge:anObject at:aReference];
    [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPATCH]];
}

-(void)deleteAt:(id<MPWReferencing>)aReference
{
    [super deleteAt:aReference];
    [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbDELETE]];
}

-(void)graphViz:(MPWByteStream*)aStream
{
    [super graphViz:aStream];
    [aStream printFormat:@"%@\n",[self graphVizName]];
    [aStream printFormat:@" -> %@ [label=log] ",[self.log graphVizName]];
    [self.log graphViz:aStream];
}

-(MPWLoggingStore*)logger
{
    return self;
}

-(void)dealloc
{
    [_log release];
    [super dealloc];
}


@end

@implementation MPWAbstractStore(logging)

-(MPWLoggingStore*)logger
{
    return [MPWLoggingStore storeWithSource:self];
}

@end

@implementation NSDictionary(logging)

-(MPWLoggingStore*)logger
{
    return [MPWLoggingStore storeWithSource:(id)self];
}

@end

#import "DebugMacros.h"

@implementation MPWLoggingStore(tests)

+(MPWGenericReference*)ref
{
    return [MPWGenericReference referenceWithPath:@"somePath"];
}

+(void)testWriteIsLogged
{
    NSMutableArray *theLog=[NSMutableArray array];
    MPWGenericReference *ref=[self ref];
    MPWLoggingStore *store=[self storeWithSource:nil loggingTo:theLog];
    [store at:ref put:@"hi"];
    INTEXPECT(theLog.count,1,@"should have logged write");
    IDEXPECT([theLog.firstObject reference],ref,@"got the reference");
    IDEXPECT([theLog.firstObject HTTPVerb],@"PUT",@"got the verb");
}

+(void)testDeleteIsLogged
{
    NSMutableArray *theLog=[NSMutableArray array];
    MPWGenericReference *ref=[self ref];
    MPWLoggingStore *store=[self storeWithSource:nil loggingTo:theLog];
    [store deleteAt:ref];
    INTEXPECT(theLog.count,1,@"should have logged delete");
    IDEXPECT([theLog.firstObject reference],ref,@"got the reference");
    IDEXPECT([theLog.firstObject HTTPVerb],@"DELETE",@"got the verb");
}

+(void)testMergeIsLogged
{
    NSMutableArray *theLog=[NSMutableArray array];
    MPWGenericReference *ref=[self ref];
    MPWLoggingStore *store=[self storeWithSource:nil loggingTo:theLog];
    [store merge:@"hi" at:ref];
    INTEXPECT(theLog.count,1,@"should have logged merge");
    IDEXPECT([theLog.firstObject reference],ref,@"got the reference");
    IDEXPECT([theLog.firstObject HTTPVerb],@"PATCH",@"got the verb");
}



+testSelectors
{
    return @[
             @"testWriteIsLogged",
             @"testDeleteIsLogged",
             @"testMergeIsLogged",
             ];
}

@end
