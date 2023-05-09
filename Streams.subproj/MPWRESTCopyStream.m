//
//  MPWRESTCopyStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/5/18.
//

#import "MPWRESTCopyStream.h"
#import <AccessorMacros.h>
#import "MPWGenericReference.h"
#import "MPWDictStore.h"
#import "MPWRESTOperation.h"


@implementation MPWRESTCopyStream

CONVENIENCEANDINIT(stream, WithSource:source target:target)
{
    self=[super init];
    self.source=source;
    self.target=target;
    return self;
}

-(void)writeObject:(id)anObject
{
    [self writeObject:anObject sender:nil];
}

-(void)writeObject:(MPWRESTOperation*)anObject sender:aSender
{
//    NSLog(@"-[%@ %@ %@]",[self className],NSStringFromSelector(_cmd),anObject);
    id <MPWReferencing> ref=anObject.reference;
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
    NSArray *children=[self.source childrenOfReference:@"."];
    for ( id ref in children ) {
        [self writeObject:[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbPUT] sender:self];
    }
}

-(void)dealloc
{
    [_source release];
    [_target release];
    [super dealloc];
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
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:@"hi"];
    MPWRESTCopyStream *s=[self _streamForTesting];
    s.target[ref]=@"value1";
    EXPECTNIL( s.source[ref],@"not yet");
    [s writeObject:[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbGET]];
    IDEXPECT( s.source[ref], @"value1",@"should have gotten");
}

+(void)testPut
{
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:@"hi"];
    MPWRESTCopyStream *s=[self _streamForTesting];
    s.source[ref]=@"value1";
    EXPECTNIL( s.target[ref],@"not yet");
    [s writeObject:[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbPUT]];
    IDEXPECT( s.target[ref], @"value1",@"should have gotten");
}

+(void)testDelete
{
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:@"hi"];
    MPWRESTCopyStream *s=[self _streamForTesting];
    s.target[ref]=@"value1";
    IDEXPECT( s.target[ref], @"value1",@"should have gotten");
    [s writeObject:[MPWRESTOperation operationWithReference:ref verb:MPWRESTVerbDELETE]];
    EXPECTNIL( s.target[ref],@"not any more");
}


+testSelectors
{
    return @[
             @"testGet",
             @"testPut",
             @"testDelete",
             ];
}

@end

