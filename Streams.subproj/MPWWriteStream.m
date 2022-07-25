/* MPWWriteStream.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWWriteStream.h>
#import "NSInvocationAdditions_lookup.h"
#import "MPWConvertFromJSONStream.h"
#import "MPWThreadSwitchStream.h"
#import "MPWBlockTargetStream.h"
#import <MPWByteStream.h>
#import "MPWResource.h"

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

-(void)setFinalTarget:newTarget
{
    if ( [self target] && [[self target] respondsToSelector:@selector(setFinalTarget:)]) {
        [(MPWFilter*)[self target] setFinalTarget:newTarget];
    } else {
        [self setTarget:newTarget];
    }
}


-(void)do:aBlock
{
    [self setFinalTarget:[MPWBlockTargetStream streamWithBlock:aBlock]];
}

-(void)writeTarget:aTarget
{
    [self writeObject:[aTarget stringValue]];
}

-(void)setTarget:aTarget {}   // MPWFilter compatibility
-target { return nil; }

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

-(void)writeString:(NSString*)s
{
    [self writeNSObject:s];
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

-(void)writeResource:(MPWResource*)aResource
{
    [self writeObject:[aResource rawData]];
}

-(void)writeEnumerator_fast:(NSEnumerator*)e spacer:spacer
{
    id nextObject;
    IMP0 getNextObject = (IMP0)[e methodForSelector:@selector(nextObject)];
    Class lastClass = nil;
    IMP1 writeOnStream = (void*)0;
    IMP1 writeSpacer = (IMP1)[spacer methodForSelector:streamWriterMessage];

    if (nil!=(nextObject=getNextObject( e, @selector(nextObject)))) {
        writeOnStream =(IMP1)[nextObject methodForSelector: streamWriterMessage];
        lastClass = *(Class*)nextObject;
        writeOnStream( nextObject, streamWriterMessage, self );
    }
    while (nil!=(nextObject=getNextObject(e, @selector(nextObject)))) {
        if ( writeSpacer ) {
            writeSpacer( spacer, streamWriterMessage, self );
        }
        if ( lastClass != *(Class*)nextObject) {
            writeOnStream = (IMP1)[nextObject methodForSelector: streamWriterMessage];
            lastClass = *(Class*)nextObject;
        }
        if (writeOnStream) {
            writeOnStream( nextObject, streamWriterMessage, self );
        }
    }
}

-defaultSpacer
{
    return @"";
}

-(void)writeEnumerator:e
{
    [self writeEnumerator:e spacer:[self defaultSpacer]];
}

-(NSString*)graphVizName
{
    return self.name ?: [super graphVizName];
}


-(void)dealloc
{
    [_name release];
    [super dealloc];
}

@end



@implementation NSData(MPWStreaming)

-(void)writeOnMPWStream:(MPWWriteStream*)aStream
{
    [aStream writeData:self];
}

@end


@implementation NSString(MPWStreaming)

-(void)writeOnMPWStream:(MPWWriteStream*)aStream
{
    [aStream writeString:self];
}

@end

@implementation NSEnumerator(MPWStreaming)

-(void)writeOnMPWStream:(MPWWriteStream*)aStream
{
    [aStream writeEnumerator:self];
}

@end

@implementation MPWResource(streaming)

-(void)writeOnMPWStream:(MPWWriteStream*)aStream
{
    [aStream writeResource:self];
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

@implementation NSObject(graphViz)

-(NSString*)generatedName
{
    return [NSString stringWithFormat:@"\"%@\"",[[NSStringFromClass(self.class) componentsSeparatedByString:@"."] lastObject]];
}

-(NSString*)graphVizName
{
    return self.generatedName;
}

-(void)graphViz:(MPWByteStream*)aStream
{
    [aStream printFormat:@"%@\n",[self graphVizName]];
}

-(NSString*)graphViz
{
    MPWByteStream *s=[MPWByteStream streamWithTarget:[NSMutableString string]];
    [self graphViz:s];
    return (NSString*)s.target;
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

-processedWith:(MPWWriteStream*)streamOrStreamClass
{
    return [(id)streamOrStreamClass process:self];
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

-(void)graphViz:(MPWByteStream*)aStream
{
    [aStream printFormat:@"\"NSMutableArray\"\n"];
}

-(void)close {}
-(void)closeLocal {}

@end



