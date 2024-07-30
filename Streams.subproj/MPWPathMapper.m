//
//  MPWPathMapper.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 14.05.21.
//

#import "MPWPathMapper.h"

@interface NSObject(pathMapping)
-(void)writeOnPathMapper:aMapper;
@end

@implementation MPWPathMapper

-(SEL)streamWriterMessage
{
    return @selector(writeOnPathMapper:);
}

-(NSString*)mapPath:(NSString*)path
{
    if ( self.prefix && [path hasPrefix:self.prefix.path] ) {
        return [path substringFromIndex:self.prefix.path.length];
    } else {
        return path;
    }
}


-(id <MPWIdentifying>)mapReference:(id <MPWIdentifying>)reference
{
    NSString *mappedPath=[self mapPath:reference.path];
    if ( mappedPath) {
        return [[(NSObject*)reference class] referenceWithPath:mappedPath];
    }
    return nil;
}

-(void)writeReference:(MPWIdentifier*)reference
{
    id <MPWIdentifying> mappedReference=[self mapReference:reference];
    if ( mappedReference) {
        FORWARD( mappedReference);
    }
}

-(void)writeRESTOperation:(MPWRESTOperation*)op
{
    id <MPWIdentifying> mappedReference=[self mapReference:op.reference];
    if ( mappedReference) {
        FORWARD( [MPWRESTOperation operationWithReference:mappedReference verb:op.verb]);
    }
}

@end


@implementation MPWIdentifier(pathMapper)

-(void)writeOnPathMapper:(MPWPathMapper*)mapper
{
    [mapper writeReference:self];
}

@end

//@implementation MPWBinding(pathMapper)
//
//-(void)writeOnPathMapper:(MPWPathMapper*)mapper
//{
//    [mapper writeBinding:self];
//}
//
//@end

@implementation MPWRESTOperation(pathMapper)

-(void)writeOnPathMapper:(MPWPathMapper*)mapper
{
    [mapper writeRESTOperation:self];
}

@end


@implementation MPWPathMapper(tests)


+(void)testRemovePrefixFromReference
{
    MPWGenericIdentifier *ref=[MPWGenericIdentifier referenceWithPath:@"/private/tmp/hello.txt"];
    MPWPathMapper *mapper=[[self new] autorelease];
    mapper.prefix=[MPWGenericIdentifier referenceWithPath:@"/private/tmp/"];
    MPWGenericIdentifier* result = [mapper processObject:ref];
    IDEXPECT( result, [MPWGenericIdentifier referenceWithPath:@"hello.txt"], @"prefix removed");
}

+(void)testRemovePrefixFromRESTOp
{
    MPWRESTOperation *ref=[MPWRESTOperation operationWithReference:[MPWGenericIdentifier referenceWithPath:@"/private/tmp/hello.txt"] verb:MPWRESTVerbPUT];
    MPWPathMapper *mapper=[[self new] autorelease];
    mapper.prefix=[MPWGenericIdentifier referenceWithPath:@"/private/tmp/"];
    MPWRESTOperation* resultOp = [mapper processObject:ref];
    IDEXPECT( resultOp.HTTPVerb, @"PUT",@"verb");
    IDEXPECT( resultOp.reference, [MPWGenericIdentifier referenceWithPath:@"hello.txt"], @"prefix removed");
}

+(NSArray*)testSelectors
{
    return @[
        @"testRemovePrefixFromReference",
        @"testRemovePrefixFromRESTOp",
    ];
}

@end
