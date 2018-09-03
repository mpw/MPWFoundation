/* MPWWriteStream.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.


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


#import "MPWWriteStream.h"
#import "NSInvocationAdditions_lookup.h"
#import "MPWConvertFromJSONStream.h"
#import "MPWDict2ObjStream.h"
#import "MPWThreadSwitchStream.h"
#import "MPWBlockTargetStream.h"

@interface MPWWriteStream(private)

-(void)writeData:(NSData*)d;


@end

@implementation MPWWriteStream

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

+stream
{
    return [[self new] autorelease];
}


-result
{
    return nil;
}


-(SEL)streamWriterMessage
{
    return @selector(writeOnMPWStream:);
}

id visObj,visStream;
SEL visSel;
-(void)writeObject:anObject sender:sender
{
    if ( anObject != nil ) {
#if FAST_MSG_LOOKUPS
      objc_msgSend( anObject, streamWriterMessage, self );        
#else
      [anObject performSelector:streamWriterMessage withObject:self];
#endif
     }
}

-(void)writeNSObject:anObject
{
    
}

-(void)writeObject:anObject
{
    [self writeObject:anObject sender:nil];
}

-(void)writeObjectAndClose:anObject
{
    [self writeObject:anObject];
    [self close];
}

-(void)writeObjectAndFlush:anObject
{
    [self writeObject:anObject];
    [self flush];
}

-(void)writeData:(NSData*)d
{
    [self writeNSObject:d];
}

-(void)flushLocal
{
    ;
}

-(void)flush
{
    [self flushLocal];
}

-(void)closeLocal
{
    [self flushLocal];
}

-(int)inflightCount
{
    return 0;
}


-(void)reportError:(NSError*)error
{
    NSLog(@"%@ encountered error: %@",self,error);
}

-(void)close
{
    [self closeLocal];
}

-(void)writeEnumerator:e spacer:spacer
{
    BOOL first=YES;
    id nextObject;
    NSAutoreleasePool *pool=[NSAutoreleasePool new];
    int objectCount=0;
    while (nil!=(nextObject=[e nextObject])){
        if ( first ) {
            first=NO;
        } else {
            if (spacer) {
//				NSLog(@"write spacer '%@' length: %d",spacer,[spacer length]);
                [self writeObject:spacer sender:self];
            }
        }
        [self writeObject:nextObject sender:self];
        if ( objectCount++ > 10 ) {
            objectCount=0;
            [pool release];
            pool=[NSAutoreleasePool new];
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



@end



@implementation NSData(MPWStreaming)

-(void)writeOnMPWStream:(MPWWriteStream*)aStream
{
    [aStream writeData:self];
}

@end

@implementation NSEnumerator(MPWStreaming)

-(void)writeOnMPWStream:(MPWWriteStream*)aStream
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

-(void)writeOnStream:(MPWWriteStream*)aStream
{
    [aStream writeEnumerator:self];
}

@end
@implementation NSObject(BaseStreaming)

-(void)writeOnMPWStream:(MPWWriteStream*)aStream
{
    [aStream writeNSObject:self];
}

-finalTarget
{
    return self;
}

-(void)writeObject:anObject {}

-(void)writeObject:anObject sender:aSender
{
    [self writeObject:anObject];
}

@end

@implementation NSMutableArray(StreamTarget)

-(void)writeObject:anObject
{
	if (anObject) {	
		[self addObject:anObject];
	}
}

-(int)inflightCount
{
    return (int)self.count;
}

@end



