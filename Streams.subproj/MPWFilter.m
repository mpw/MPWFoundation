//
//  MPWFilter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/2/18.
//

#import "MPWFilter.h"
#import "MPWRuntimeAdditions.h"
#import "NSInvocationAdditions_lookup.h"


@implementation MPWFilter

+(instancetype)stream
{
    return [self streamWithTarget:[self defaultTarget]];
}


+(instancetype)streamWithTarget:aTarget
{
    return [[[self alloc] initWithTarget:aTarget] autorelease];
}

-(instancetype)initWithTarget:aTarget
{
    self = [super init];
    self.target = aTarget;
    streamWriterMessage = [self streamWriterMessage];
    return self;
}

-init
{
    return [self initWithTarget:[[self class] defaultTarget]];
}


-(void)writeNSObject:anObject
{
    FORWARD( anObject );
}

-(void)forward:anObject
{
    FORWARD( anObject );
}

-(void)flush:(int)n
{
    [self flushLocal];
    if ( n>0 ) {
        [(MPWFilter*)self.target flush:n-1];
    }
}

-(void)flush
{
    [self flush:65535 * 16383];
}

-(void)close:(int)n
{
    [self closeLocal];
    if ( n>0 ) {
        [(MPWFilter*)self.target close:n-1];
    }
}

-(void)close
{
    [self close:65535 * 16383];
}

idAccessor( _target, _setTarget )

-(MPWWriteStream *)target
{
    return _target;
}

-(void)setTarget:newTarget
{
    [self _setTarget:newTarget];
    targetWriteObject = (IMP_2_id_args)[_target methodForSelector:@selector(writeObject:sender:)];
#ifdef Darwin
    if ( targetWriteObject == NULL ) {
        targetWriteObject = (IMP_2_id_args)objc_msgSend;
    }
#endif
}

-(void)insertStream:aStream
{
    [aStream setTarget:[self target]];
    [self setTarget:aStream];
}

-finalTarget
{
    return [_target finalTarget];
}

-result
{
    return [self finalTarget];
}

-(void)dealloc
{
    [_target release];
    [super dealloc];
}

-processObject:anObject
{
    [self writeObjectAndFlush:anObject];
    id result=[self finalTarget];
    if ( [result respondsToSelector:@selector(firstObject)] && [result count]==1) {
        NSMutableArray *a=result;
        result=[a firstObject];
        [a removeObjectAtIndex:0];
    }
    return result;
}

-process:anObject
{
    return [self processObject:anObject];
}



-firstObject { return [[self finalTarget] firstObject]; }
-lastObject { return [[self finalTarget] lastObject]; }

+defaultTarget
{
    return [NSMutableArray array];
}

-(void)graphViz:(MPWByteStream*)output
{
    [super graphViz:output];
    if ( self.target ) {
        [output writeObject:@" -> "];
        [self.target graphViz:output];
    }
}

-(int)runWithStdin:(id <StreamSource>)source Stdout:(MPWByteStream*)target
{
    [source setTarget:self];
    [self setTarget:target];
    [source run];
}

+(int)runWithStdin:(id <StreamSource>)source Stdout:(MPWByteStream*)target
{
    return [[self streamWithTarget:target] runWithStdin:source Stdout:target];
}

@end



@implementation MPWFilter(testing)

+(void)testDefaultStreamTarget
{
    MPWFilter* stream=[self stream];
    NSAssert1( [[stream target] isKindOfClass:[NSMutableArray class]] , @"stream target not NSArray but %@ instead",[[stream target] class]);
    (void)stream;
}


+testSelectors
{
    return @[
                         @"testDefaultStreamTarget",
             ];
}

@end
