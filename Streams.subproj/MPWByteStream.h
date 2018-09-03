/* MPWByteStream.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.


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


#import "MPWFlattenStream.h"

// typedef id (*IMP0)(id, SEL, ...);

@protocol ByteStreaming


-(void)appendBytes:(const void*)data length:(NSUInteger)count;
-(void)appendBytesAsHex:(const void*)data length:(NSUInteger)count;
-(void)printf:(NSString*)format,...;
-(void)printLine:(NSString*)format,...;
-(void)printFormat:(NSString*)format,...;
-(NSUInteger)length;
-(void)writeNewline;
-(void)writeSpace;
-(void)writeTab;
-(void)writeNull;
-(void)writeCString:(const char*)cString;

@end

typedef id (*APPENDIMP)(id, SEL, char *, long);


@interface MPWByteStream : MPWFlattenStream<ByteStreaming>
{
    unsigned long totalBytes;
    APPENDIMP	targetAppend;
    int indent;
	int indentAmount;
    id  byteTarget;
}

+(NSString*)makeString:anObject;
+(instancetype)Stdout;
+(instancetype)Stderr;
+(instancetype)file:(FILE*)file;
+(instancetype)fileName:(NSString*)fileName;
+(instancetype)null;

-(void)writeIndent;
-(void)writeString:(NSString*)aString;
-(long)targetLength;
-(void)outputString:(NSString*)aString;
-(void)indent;
-(void)outdent;
-(void)setIndentAmount:(int)indent;
-(void)writeObject:anObject forKey:aKey;
-(void)println:anObject;
-(void)print:anObject;

#define  TARGET_APPEND( data, count)   { targetAppend( self->byteTarget, @selector(appendBytes:length:), data , count ); self->totalBytes+=count; }

#define FORWARDCHARSLEN( x,l )  [self->byteTarget appendBytes:(x) length:(l)]
#define FORWARDCHARS( x )       FORWARDCHARSLEN( x,strlen(x))

@end


@interface NSObject(ByteStreaming)

-(void)writeOnByteStream:(MPWByteStream*)aStream;

@end

