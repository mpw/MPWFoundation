//
//  MPWLoggingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/3/18.
//

#import "MPWLoggingStore.h"
#import "MPWGenericIdentifier.h"
#import <AccessorMacros.h>
#import "MPWRESTOperation.h"
#import <MPWByteStream.h>

@implementation MPWLoggingStore


-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource
{
    self=[super initWithSource:newSource];
    self.loggingFlags = MPWRESTVerbsWrite;
    return self;
}

CONVENIENCEANDINIT( store , WithSource:(NSObject <MPWStorage,MPWHierarchicalStorage>*)aSource loggingTo:(id <Streaming>)log )
{
    self=[self initWithSource:aSource];
    self.log=(NSObject <Streaming>*)log;
    return self;
}

-(id)at:(id<MPWIdentifying>)aReference
{
    if ( self.loggingFlags & MPWRESTVerbGET) {
        [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbGET]];
    }
    return [super at:aReference];
}

-(void)at:(id<MPWIdentifying>)aReference put:anObject
{
    [super at:aReference put:anObject];
    if ( self.loggingFlags & MPWRESTVerbPUT) {
        [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPUT]];
    }
}

-(id)at:(id<MPWIdentifying>)aReference post:anObject
{
    id returnValue = [super at:aReference post:anObject];
    if ( self.loggingFlags & MPWRESTVerbPOST) {
        [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPOST]];
    }
    return returnValue;
}

-(void)merge:anObject at:(id<MPWIdentifying>)aReference
{
    [super merge:anObject at:aReference];
    [self.log writeObject:[MPWRESTOperation operationWithReference:aReference verb:MPWRESTVerbPATCH]];
}

-(void)deleteAt:(id<MPWIdentifying>)aReference
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

+(MPWGenericIdentifier*)ref
{
    return [MPWGenericIdentifier referenceWithPath:@"somePath"];
}

+(void)testWriteIsLogged
{
    NSMutableArray *theLog=[NSMutableArray array];
    MPWGenericIdentifier *ref=[self ref];
    MPWLoggingStore *store=[self storeWithSource:nil loggingTo:theLog];
    [store at:ref put:@"hi"];
    INTEXPECT(theLog.count,1,@"should have logged write");
    IDEXPECT([theLog.firstObject identifier],ref,@"got the reference");
    IDEXPECT([theLog.firstObject HTTPVerb],@"PUT",@"got the verb");
}

+(void)testDeleteIsLogged
{
    NSMutableArray *theLog=[NSMutableArray array];
    MPWGenericIdentifier *ref=[self ref];
    MPWLoggingStore *store=[self storeWithSource:nil loggingTo:theLog];
    [store deleteAt:ref];
    INTEXPECT(theLog.count,1,@"should have logged delete");
    IDEXPECT([theLog.firstObject identifier],ref,@"got the reference");
    IDEXPECT([theLog.firstObject HTTPVerb],@"DELETE",@"got the verb");
}

+(void)testMergeIsLogged
{
    NSMutableArray *theLog=[NSMutableArray array];
    MPWGenericIdentifier *ref=[self ref];
    MPWLoggingStore *store=[self storeWithSource:nil loggingTo:theLog];
    [store merge:@"hi" at:ref];
    INTEXPECT(theLog.count,1,@"should have logged merge");
    IDEXPECT([theLog.firstObject identifier],ref,@"got the reference");
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
