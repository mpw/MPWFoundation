/* MPWWriteStream.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>
#import "AccessorMacros.h"
#import "MPWObject.h"


@protocol Streaming

-(void)writeObject:anObject;

@end

@class MPWByteStream;

@protocol StreamSource

@property (nonatomic, strong) IBOutlet NSObject <Streaming> *target;

@end

@interface NSObject(MPWStreaming)

-(void)writeOnStream:(id <Streaming>)aStream;

@end

@interface NSObject(graphViz)

-(void)graphViz:(MPWByteStream*)aStream;
-(NSString*)graphViz;
-(NSString*)graphVizName;

@end


@interface MPWWriteStream : NSObject <Streaming>
{
    SEL streamWriterMessage;
}

@property (nonatomic, strong) NSString *name;

+process:anObject;
+(void)processAndIgnore:anObject;
-(void)writeObjectAndClose:anObject;
-(void)writeObject:anObject sender:sourceStream;
-(void)writeEnumerator:e spacer:spacer;
-(void)writeEnumerator:e;
-(void)writeNSObject:anObject;
-(void)writeData:(NSData*)d;
+(instancetype)stream;
//-(instancetype)init;
-(void)writeObjectAndFlush:anObject;


-(SEL)streamWriterMessage;
-(void)close;
-(void)flush;
-result;

-(void)closeLocal;
-(void)flushLocal;

-(void)reportError:(NSError*)error;




@end

@interface NSObject(BaseStreaming)

-(void)writeOnMPWStream:(MPWWriteStream*)aStream;
@end


@interface NSMutableArray(StreamTarget) <Streaming>

@end

