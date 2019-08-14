//
//  MPWLoggingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/3/18.
//

#import "MPWLoggingStore.h"
#import "MPWGenericReference.h"
#import "AccessorMacros.h"
#import "MPWRESTOperation.h"
#import "MPWByteStream.h"

@implementation MPWLoggingStore

CONVENIENCEANDINIT( store , WithSource:(NSObject <MPWStorage,MPWHierarchicalStorage>*)aSource loggingTo:(id <Streaming>)log )
{
    self=[super initWithSource:aSource];
    self.log=(NSObject <Streaming>*)log;
    return self;
}

-(void)setObject:anObject forReference:(id<MPWReferencing>)aReference
{
    [super setObject:anObject forReference:aReference];
    [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPUT]];
}

-(void)mergeObject:anObject forReference:(id<MPWReferencing>)aReference
{
    [super mergeObject:anObject forReference:aReference];
    [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPATCH]];
}

-(void)deleteObjectForReference:(id<MPWReferencing>)aReference
{
    [super deleteObjectForReference:aReference];
    [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbDELETE]];
}

-(void)graphViz:(MPWByteStream*)aStream
{
    [super graphViz:aStream];
    [aStream printFormat:@"%@\n",[self graphVizName]];
    [aStream printFormat:@" -> %@ [label=log] ",[self.log graphVizName]];
    [self.log graphViz:aStream];
}


-(void)dealloc
{
    [_log release];
    [super dealloc];
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
    [store setObject:@"hi" forReference:ref];
    INTEXPECT(theLog.count,1,@"should have logged write");
    IDEXPECT([theLog.firstObject reference],ref,@"got the reference");
    IDEXPECT([theLog.firstObject HTTPVerb],@"PUT",@"got the verb");
}

+(void)testDeleteIsLogged
{
    NSMutableArray *theLog=[NSMutableArray array];
    MPWGenericReference *ref=[self ref];
    MPWLoggingStore *store=[self storeWithSource:nil loggingTo:theLog];
    [store deleteObjectForReference:ref];
    INTEXPECT(theLog.count,1,@"should have logged delete");
    IDEXPECT([theLog.firstObject reference],ref,@"got the reference");
    IDEXPECT([theLog.firstObject HTTPVerb],@"DELETE",@"got the verb");
}

+(void)testMergeIsLogged
{
    NSMutableArray *theLog=[NSMutableArray array];
    MPWGenericReference *ref=[self ref];
    MPWLoggingStore *store=[self storeWithSource:nil loggingTo:theLog];
    [store mergeObject:@"hi" forReference:ref];
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
