//
//  MPWRESTCopyStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/5/18.
//

#import "MPWRESTCopyStream.h"
#import <AccessorMacros.h>
#import "MPWGenericIdentifier.h"
#import "MPWDictStore.h"
#import "MPWRESTOperation.h"
#import "MPWStructureDefinition.h"
#import "MPWVariableDefinition.h"


@interface NSObject(RESTCopying)

-(void)writeOnRESTCopyStream:aStream;

@end

@implementation MPWRESTCopyStream

CONVENIENCEANDINIT(stream, WithSource:source target:target)
{
    self=[super init];
    self.source=source;
    self.target=target;
    return self;
}

-(SEL)streamWriterMessage
{
    return @selector(writeOnRESTCopyStream:);
}

-(void)writeRESTOperation:(MPWRESTOperation*)anObject
{
    NSLog(@"-[%@ %@ %@]",[self className],NSStringFromSelector(_cmd),anObject);
    id <MPWIdentifying> ref=anObject.identifier;
    switch (anObject.verb) {
        case MPWRESTVerbGET:
            self.source[ref]=self.target[ref];
            break;
        case MPWRESTVerbPUT:
//            NSLog(@"put from: %@ to %@",self.target,self.source);
//            NSLog(@"data: %@",self.source[ref]);
            self.target[ref]=self.source[ref];
          break;
        case MPWRESTVerbDELETE:
            self.target[ref]=nil;
            break;
        default:
            break;
            
    }
}

-(void)update
{
    [self copyStructureDefinition:[self.source structureForReference:@"."]];
}

-(void)copyReferences:(NSArray*)references
{
    for ( id ref in references ) {
        [self writeObject:[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbPUT] sender:self];
    }
}

-(void)copyFields:(NSArray<MPWVariableDefinition*>*)fields prefix:(NSString*)prefix
{
    for (MPWVariableDefinition *field in fields) {
        NSString *path=prefix.length ? [prefix stringByAppendingPathComponent:field.name] : field.name;
        if ([field.type isKindOfClass:[MPWStructureDefinition class]]) {
            [self.target mkdirAt:[self.target referenceForPath:path]];
            [self copyFields:((MPWStructureDefinition*)field.type).fields prefix:path];
        } else {
            [self copyReferences:@[ [self.source referenceForPath:path] ]];
        }
    }
}

-(void)copyStructureDefinition:(MPWStructureDefinition*)structure
{
    [self copyFields:structure.fields prefix:@""];
}

-(void)dealloc
{
    [_source release];
    [_target release];
    [super dealloc];
}

@end

@implementation NSObject(RESTCopying)

-(void)writeOnRESTCopyStream:aStream
{
    [self writeOnStream:aStream];
}

@end

@implementation MPWRESTOperation(RESTCopying)

-(void)writeOnRESTCopyStream:(MPWRESTCopyStream*)aStream
{
    [aStream writeRESTOperation:self];
}

@end

@implementation MPWStructureDefinition(RESTCopying)

-(void)writeOnRESTCopyStream:(MPWRESTCopyStream*)aStream
{
    [aStream copyStructureDefinition:self];
}

@end

#import "DebugMacros.h"

@implementation MPWRESTCopyStream(testing)

+_streamForTesting
{
    return [self streamWithSource:[MPWDictStore store] target:[MPWDictStore store]];
}

+(void)testGet
{
    MPWGenericIdentifier *ref=[MPWGenericIdentifier referenceWithPath:@"hi"];
    MPWRESTCopyStream *s=[self _streamForTesting];
    s.target[ref]=@"value1";
    EXPECTNIL( s.source[ref],@"not yet");
    [s writeObject:[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbGET]];
    IDEXPECT( s.source[ref], @"value1",@"should have gotten");
}

+(void)testPut
{
    MPWGenericIdentifier *ref=[MPWGenericIdentifier referenceWithPath:@"hi"];
    MPWRESTCopyStream *s=[self _streamForTesting];
    s.source[ref]=@"value1";
    EXPECTNIL( s.target[ref],@"not yet");
    [s writeObject:[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbPUT]];
    IDEXPECT( s.target[ref], @"value1",@"should have gotten");
}

+(void)testDelete
{
    MPWGenericIdentifier *ref=[MPWGenericIdentifier referenceWithPath:@"hi"];
    MPWRESTCopyStream *s=[self _streamForTesting];
    s.target[ref]=@"value1";
    IDEXPECT( s.target[ref], @"value1",@"should have gotten");
    [s writeObject:[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbDELETE]];
    EXPECTNIL( s.target[ref],@"not any more");
}

+(void)testCopyExplicitReferences
{
    MPWRESTCopyStream *s=[self _streamForTesting];
    s.source[@"one"]=@"1";
    s.source[@"two"]=@"2";
    s.source[@"not-copied"]=@"3";
    [s copyReferences:@[ @"one", @"two" ]];
    IDEXPECT(s.target[@"one"], @"1", @"copied first explicit reference");
    IDEXPECT(s.target[@"two"], @"2", @"copied second explicit reference");
    EXPECTNIL(s.target[@"not-copied"], @"only explicit references are copied");
}


+testSelectors
{
    return @[
             @"testGet",
             @"testPut",
             @"testDelete",
             @"testCopyExplicitReferences",
             ];
}

@end
