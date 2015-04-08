/* MPWStream.m Copyright (c) 1998-2015 by Marcel Weiher, All Rights Reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

	Redistributions of source code must retain the above copyright
	notice, this list of conditions and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in
	the documentation and/or other materials provided with the distribution.

	Neither the name Marcel Weiher nor the names of contributors may
	be used to endorse or promote products derived from this software
	without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

*/


#import "MPWStream.h"
#import "MPWRuntimeAdditions.h"
#import "NSInvocationAdditions_lookup.h"
#import "MPWConvertFromJSONStream.h"
#import "MPWDict2ObjStream.h"
#import "MPWThreadSwitchStream.h"
#import "MPWBlockTargetStream.h"

@interface MPWStream(private)

-(void)writeData:(NSData*)d;


@end

@implementation MPWStream

+process:anObject
{
    id stream = [self stream];
    [stream writeObjectAndClose:anObject];
    return [stream result];
}

+(void)processAndIgnore:anObject
{
    NSAutoreleasePool* pool=[[NSAutoreleasePool alloc] init];
    [self process:anObject];
    [pool drain];
}

+defaultTarget
{
    return [NSMutableArray array];
}

+stream
{
    id pool=[[NSAutoreleasePool alloc] init];
    id stream = [[self alloc] initWithTarget:[self defaultTarget]];
    [pool release];
    return [stream autorelease];
}

+streamWithObject:anObject
{
    id stream=[self stream];
    [stream writeObject:anObject];
    return stream;
}

+streamWithTarget:aTarget
{
    return [[[self alloc] initWithTarget:aTarget] autorelease];
}

-initWithTarget:aTarget
{
    self = [super init];
    [self setTarget:aTarget];
    streamWriterMessage = [self streamWriterMessage];
    return self;
}

-init
{
    return [self initWithTarget:[[self class] defaultTarget]];
}

-(void)dealloc
{
    [target release];
    [super dealloc];
}

idAccessor( target, _setTarget )

-finalTarget
{
    return [target finalTarget];
}

-(void)setFinalTarget:newTarget
{
    if ( [self target] && [[self target] respondsToSelector:@selector(setFinalTarget:)]) {
        [[self target] setFinalTarget:newTarget];
    } else {
        [self setTarget:newTarget];
    }
}

-result
{
    return [self finalTarget];
}


-(void)setTarget:newTarget
{
    [self _setTarget:newTarget];
    targetWriteObject = (IMP0)[target methodForSelector:@selector(writeObject:)];
#ifdef Darwin
    if ( targetWriteObject == NULL ) {
        targetWriteObject = (IMP0)objc_msgSend;
    }
#endif
}


-(void)insertStream:aStream
{
    [aStream setTarget:[self target]];
    [self setTarget:aStream];
}

-(SEL)streamWriterMessage
{
    return @selector(writeOnMPWStream:);
}

id visObj,visStream;
SEL visSel;
-(void)writeObject:anObject
{
    if ( anObject != nil ) {
#if FAST_MSG_LOOKUPS
      objc_msgSend( anObject, streamWriterMessage, self );        
#else
      [anObject performSelector:streamWriterMessage withObject:self];
#endif
    } else {
        [target writeObject:nil];
    }
}

-(void)writeObjectAndClose:anObject
{
    [self writeObject:anObject];
    [self close];
}

-(void)writeNSObject:anObject
{
    FORWARD( anObject );
}

-(void)writeData:(NSData*)d
{
    [self writeNSObject:d];
}

-(void)flushLocal
{
    ;
}

-(void)flush:(int)n
{    
    [self flushLocal];
    if ( n>0 ) {
        [target flush:n-1];
    }
}

-(void)flush
{
    [self flush:65535 * 16383];
}

-(void)closeLocal
{
    [self flushLocal];
}

-(void)close:(int)n
{
    [self closeLocal];
    if ( n>0 ) {
        [target close:n-1];
    }
}

-(void)reportError:(NSError*)error
{
    NSLog(@"%@ encountered error: %@",self,error);
}

-(void)close
{
    [self close:65535 * 16383];
}

-(void)writeEnumerator:e spacer:spacer
{
    BOOL first=YES;
    id nextObject;
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    int objectCount=0;
    while (nil!=(nextObject=[e nextObject])){
        if ( first ) {
            first=NO;
        } else {
            if (spacer) {
//				NSLog(@"write spacer '%@' length: %d",spacer,[spacer length]);
                [self writeObject:spacer];
            }
        }
        [self writeObject:nextObject];
        if ( objectCount++ > 10 ) {
            objectCount=0;
            [pool release], pool=[[NSAutoreleasePool alloc] init];
        }
    }
    [pool drain];
}

-(void)writeEnumerator_fast:(NSEnumerator*)e spacer:spacer
{
    id nextObject;
    IMP0 getNextObject = (IMP0)[e methodForSelector:@selector(nextObject)];
    Class lastClass = nil;
    IMP0 writeOnStream = (void*)0;
    IMP0 writeSpacer = (IMP0)[spacer methodForSelector:streamWriterMessage];

    if (nil!=(nextObject=getNextObject( e, @selector(nextObject)))) {
        writeOnStream =(IMP0)[nextObject methodForSelector: streamWriterMessage];
        lastClass = *(Class*)nextObject;
        writeOnStream( nextObject, streamWriterMessage, self );
    }
    while (nil!=(nextObject=getNextObject(e, @selector(nextObject)))) {
        if ( writeSpacer ) {
            writeSpacer( spacer, streamWriterMessage, self );
        }
        if ( lastClass != *(Class*)nextObject) {
            writeOnStream = (IMP0)[nextObject methodForSelector: streamWriterMessage];
            lastClass = *(Class*)nextObject;
        }
        if (writeOnStream) {
            writeOnStream( nextObject, streamWriterMessage, self );
        }
    }
}

-defaultSpacer
{
    return nil;
}

-(void)writeEnumerator:e
{
    [self writeEnumerator:e spacer:[self defaultSpacer]];
}

#pragma mark convenience

-parseJSONWithKey:(NSString*)key
{
    [self setFinalTarget:[MPWConvertFromJSONStream streamWithKey:key target:nil]];
    return self;
}

-dict2objWithClass:(Class)targetClass selector:(SEL)creationSelector
{
    [self setFinalTarget:[MPWDict2ObjStream streamWithClass:targetClass selector:creationSelector target:nil]];
    
    return self;
}

-dict2objWithClass:(Class)targetClass
{
    return [self dict2objWithClass:targetClass selector:NULL];
}

-onMainThreadStream
{
    [self setFinalTarget:[MPWThreadSwitchStream streamWithTarget:nil]];
    
    return self;
}

-onBlock:aBlock
{
    [self setFinalTarget:[MPWBlockTargetStream streamWithBlock:aBlock]];
    
    return self;
}

@end

@implementation MPWStream(testing)

+(void)defaultStreamTarget
{
    MPWStream* stream=[MPWStream stream];
    NSAssert1( [[stream target] isKindOfClass:[NSMutableArray class]] , @"stream target not NSArray but %@ instead",[[stream target] class]);
}

+testSelectors
{
    return [NSArray arrayWithObjects:@"defaultStreamTarget",nil];
}


@end

@implementation NSData(MPWStreaming)

-(void)writeOnMPWStream:(MPWStream*)aStream
{
    [aStream writeData:self];
}

@end

@implementation NSEnumerator(MPWStreaming)

-(void)writeOnMPWStream:(MPWStream*)aStream
{
    [aStream writeEnumerator:self];
}

@end

@implementation NSObject(MPWStreaming)

-(void)writeOnStream:(id <Streaming>)aStream
{
    [aStream writeObject:self];
}

-(void)flush:(int)n
{
    ;
}

-(void)close:(int)n
{
    ;
}

@end

@implementation NSEnumerator(streaming)

-(void)writeOnStream:(MPWStream*)aStream
{
    [aStream writeEnumerator:self];
}

@end
@implementation NSObject(BaseStreaming)

-(void)writeOnMPWStream:(MPWStream*)aStream
{
    [aStream writeNSObject:self];
}

-finalTarget
{
    return self;
}

@end

@implementation NSMutableArray(StreamingTarget)

-(void)writeObject:anObject
{
	if (anObject) {	
		[self addObject:anObject];
	}
}

@end

