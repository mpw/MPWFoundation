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

-(void)setFinalTarget:newTarget
{
    if ( [self target] && [[self target] respondsToSelector:@selector(setFinalTarget:)]) {
        [[self target] setFinalTarget:newTarget];
    } else {
        [self setTarget:newTarget];
    }
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
        [self.target flush:n-1];
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
        [self.target close:n-1];
    }
}

-(void)close
{
    [self close:65535 * 16383];
}

idAccessor( _target, _setTarget )

-(MPWStream *)target
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

-firstObject { return [[self finalTarget] firstObject]; }
-lastObject { return [[self finalTarget] lastObject]; }

@end



@implementation MPWFilter(testing)

+(void)testDefaultStreamTarget
{
    MPWFilter* stream=[self stream];
    NSAssert1( [[stream target] isKindOfClass:[NSMutableArray class]] , @"stream target not NSArray but %@ instead",[[stream target] class]);
    (void)stream;
}

+(void)testForwardingWorks
{
    
}

+testSelectors
{
    return @[
             
                         @"testDefaultStreamTarget",
             ];
}

@end
