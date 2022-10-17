/* MPWByteStream.h Copyright (c) 1998-2021 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWFoundation/MPWFlattenStream.h>

// typedef id (*IMP0)(id, SEL, ...);

@class MPWAbstractStore;

@protocol ByteStreaming


-(void)appendBytes:(const void*)data length:(NSUInteger)count;
-(void)appendBytesAsHex:(const void*)data length:(NSUInteger)count;
-(void)printf:(NSString*)format,...;
-(void)printLine:(NSString*)format,...;
-(void)printFormat:(NSString*)format,...;
-(void)writeNewline;
-(void)writeSpace;
-(void)writeTab;
-(void)writeNull;
-(void)writeCString:(const char*)cString;
-(NSUInteger)length;

@end

typedef id (*APPENDIMP)(id, SEL, char *, long);


@interface MPWByteStream : MPWFlattenStream<ByteStreaming>
{
    unsigned long totalBytes;
    APPENDIMP	targetAppend;
    int indent;
	int indentAmount;
    id  byteTarget;
    NSMutableSet *alreadySeen;
}

+(NSString*)makeString:anObject;
+(instancetype)Stdout;
+(instancetype)Stderr;
+(instancetype)file:(FILE*)file;
+fd:(int)fd;
+(instancetype)fileName:(NSString*)fileName;
+fileName:(NSString*)fileName mode:(NSString*)mode atomically:(BOOL)atomic;
+(instancetype)null;
-(void)setByteTarget:newTarget;

-(void)writeIndent;
-(void)writeString:(NSString*)aString;
-(void)writeNullTerminatedString:(NSString*)aString;
-(long)targetLength;
-(void)outputString:(NSString*)aString;
-(void)indent;
-(void)outdent;
-(void)setIndentAmount:(int)indent;
-(void)writeObject:anObject forKey:aKey;
-(void)println:anObject;
-(void)print:anObject;
-(void)writeInterpolatedString:(NSString*)s withEnvironment:(MPWAbstractStore*)env;
-(void)beginObject:anObject;
-(void)endObject:anObject;


#define  TARGET_APPEND( data, count)   { targetAppend( self->byteTarget, @selector(appendBytes:length:), data , count ); self->totalBytes+=count; }

#define FORWARDCHARSLEN( x,l )  [self->byteTarget appendBytes:(x) length:(l)]
#define FORWARDCHARS( x )       FORWARDCHARSLEN( x,strlen(x))

@end


@interface NSObject(ByteStreaming)

-(void)writeOnByteStream:(MPWByteStream*)aStream;

@end

