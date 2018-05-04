/* MPWByteStream.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.


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


#import "MPWByteStream.h"
#import "bytecoding.h"
#import "DebugMacros.h"

@interface NSString(fastCString)

-( char*)_fastCStringContents:(BOOL)blah;

@end

@interface MPWNullTarget : NSObject

@end


@interface MPWStdioTarget : NSObject
{
    FILE *outfile;
    BOOL doClose;
    NSString*	tempFileName;
    NSString*	finalFileName;	
}

+Stdout;
+Stderr;
+fileTarget:(FILE*)newFile;
+fileNameTarget:(NSString*)fileName mode:(NSString*)mode;
-initWithFile:(FILE*)newFile;

@end

@interface MPWFileDescriptorTarget : NSObject
{
	int	fd;
}

-initWithFd:(int)newFd;
+fd:(int)newFd;

@end



@interface MPWForwardingTarget : NSObject
{
	id target;
	SEL selector;
}

-initWithTarget:newTarget selector:(SEL)newSelector;
+forwarderWithTarget:data selector:(SEL)newSelector;

@end


@implementation MPWByteStream

idAccessor(byteTarget, _setByteTarget)

-(id)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:nil];
    [self setByteTarget:aTarget];
    [self setIndentAmount:4];

    return self;
}

-unusedTarget
{
    return [super target];
}

-(id)target
{
    return [self byteTarget];
}

-(void)writeIndent
{
	char  spaces[] = "                                                                                            ";
	int spacelen=(sizeof spaces) -1;
	int indentLen=indent*indentAmount;
	if (indentLen ) {
		if ( indentLen > spacelen ) {
			indentLen=spacelen;
		}
        TARGET_APPEND(spaces, indentLen);
//		[self appendBytes:spaces length:indentLen];
	}
}




+stringStream
{
	return [self streamWithTarget:[NSMutableString string]];
}

+(NSString*)makeString:anObject
{
    id stream = [self stringStream];
    [stream writeObject:anObject];
    return [stream result];
}

+defaultTarget
{
    return [NSMutableData data];
}

+Stdout
{
	static id Stdout=nil;
	if ( !Stdout ) {
		Stdout = [[self streamWithTarget:[MPWStdioTarget Stdout]] retain];
	}
	return Stdout;
}

+Stderr
{
	static id Stderr=nil;
	if ( !Stderr ) {
		Stderr = [[self streamWithTarget:[MPWStdioTarget Stderr]] retain];
	}
	return Stderr;
}

+fd:(int)fd
{
	return [self streamWithTarget:[MPWFileDescriptorTarget fd:fd]];
}

+file:(FILE*)file
{
    return [self streamWithTarget:[MPWStdioTarget fileTarget:file]];
}

+null
{
    return [self streamWithTarget:[[[MPWNullTarget alloc] init] autorelease]];
}

+(NSString*)defaultFileMode
{
    return @"w";
}


+fileName:(NSString*)fileName mode:(NSString*)mode
{
    return [self streamWithTarget:[MPWStdioTarget fileNameTarget:fileName mode:mode]];
}

+fileName:(NSString*)fileName
{
    return [self fileName:fileName mode:[self defaultFileMode]];
}


-(void)indent
{
	indent++;
}
-(void)outdent
{
	indent--;
	indent=MAX(indent,0);
}

intAccessor( indentAmount , setIndentAmount )

-(void)setByteTarget:newTarget
{
    totalBytes=0;
	SEL targetAppendSelector = @selector(appendBytes:length:);
    targetAppend=(APPENDIMP)[newTarget methodForSelector:targetAppendSelector];
	if ( targetAppend == NULL ) {
        
//		[NSException raise:@"InvalidTarget" format:@"target: %@ does not respond to %@",newTarget,NSStringFromSelector(targetAppendSeleector)];
	}
    [self _setByteTarget:newTarget];
}

-(void)setTarget:(id)newVar
{
    ;
}

-(void)writeNSObject:anNSObject
{
    [self outputString: [anNSObject stringValue]];
}

-(void)writeNewline
{
    [self writeCString:"\n"];
}

-(void)writeSpace
{
    [self writeCString:" "];
}

-(void)writeTab
{
    [self writeCString:"\t"];
}

-(void)writeNull
{
    [self appendBytes:"" length:1];
}

-(SEL)streamWriterMessage
{
    return @selector(writeOnByteStream:);
}

-(void)appendBytes:(const void*)data length:(NSUInteger)count
{
    TARGET_APPEND( (char*)data , count );
}

-(void)appendBytesAsHex:(const void*)data length:(NSUInteger)count
{
    unsigned char hexbytes[count*2+10];
    hexencode( data, hexbytes, (int)count );
    [self appendBytes:hexbytes length:count*2];
}

-(void)appendDataAsHex:(NSData*)unencodedData
{
    [self appendBytesAsHex:[unencodedData bytes] length:[unencodedData length]];
}

-(void)writeCString:(const char*)cString
{
    TARGET_APPEND((char*)cString, strlen(cString));
}

-(NSStringEncoding)outputEncoding
{
    return NSUTF8StringEncoding;
}

-(void)outputString:(NSString*)aString
{
#define MAXLEN 8192

    char buffer[MAXLEN];
    long length=[aString length];
    NSRange range={0,length};
    NSRange remainingRange;

    while (range.length > 0) {
        NSUInteger usedBufferCount;
        [aString getBytes:buffer maxLength:MAXLEN
               usedLength:&usedBufferCount
                 encoding:[self outputEncoding]
                  options:0
                    range:range
           remainingRange:&remainingRange];
        TARGET_APPEND(buffer, usedBufferCount);
        range=remainingRange;
    }
}

-(void)writeString:(NSString*)string
{
//	NSLog(@"-[MPWByteStream writeString:%@]",string);
	[self outputString:string];
}

-(void)writeData:(NSData*)data
{
    TARGET_APPEND((char*)[data bytes], [data length]);
}

-(void)printf:(NSString*)format args:(va_list)ap
{
    char fmt[[format length]+10];
    char buf[10000];
    int bytes;
	[format getCString:fmt maxLength:[format length]+1 encoding:NSASCIIStringEncoding];
    fmt[[format length]]=0;
    bytes = vsprintf(buf, fmt,ap);
    [self appendBytes:buf length:bytes];
}


-(void)printf:(NSString*)format,...
{
    va_list ap;
    va_start(ap,format);
    [self printf:format args:ap];
	va_end(ap);
}


-(void)printFormat:(NSString *)format args:(va_list)ap
{
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:ap];
    [self outputString:formattedString];
    [formattedString release];
}

-(void)printFormat:(NSString*)format,...
{
    va_list ap;
    va_start(ap, format);
    [self printFormat:format args:ap];
    va_end(ap);
}

-(void)printLine:(NSString*)format,...
{
    va_list ap;
    va_start(ap,format);
    [self printFormat:format args:ap];
	va_end(ap);
    [self appendBytes:"\n" length:1];
}

-(void)print:anObject
{
	if ( [anObject isKindOfClass:[NSString class]] ) {
		[self outputString:anObject];
	} else {
		[self writeObject:anObject];
	}
}

-(void)println:anObject
{
    [self print:anObject];
    [self writeNewline];
}

-(NSUInteger)length
{
    return totalBytes;
}

-(long)targetLength
{
    return [target targetLength];
}

-(void)writeObject:anObject forKey:aKey
{
    [self writeIndent];
    [self writeObject:aKey];
    [self appendBytes:" = " length:3];
    [self writeObject:anObject];
    [self appendBytes:";\n" length:2];
}

-(void)writeDictionaryContent:(NSDictionary *)dict
{
	for ( NSString *key in [[dict allKeys] sortedArrayUsingSelector:@selector(compare:)] ) {
		[self writeObject:[dict objectForKey:key] forKey:key];
	}
}

-(void)writeDictionary:(NSDictionary*)dict
{
    [self appendBytes:"{\n" length:2];
	[self indent];
	[self writeDictionaryContent:dict];
	[self outdent];
	[self writeIndent];
    [self appendBytes:"}" length:2];
}


-(NSString*)description
{
	return [NSString stringWithFormat:@"<%@/%p: byteTarget %@/%p",[self class],self,[target class],byteTarget];
}


-(void)dealloc
{
    [byteTarget release];
    [super dealloc];
}

-finalTarget
{
    return [self byteTarget];
}

@end


@implementation NSObject(ByteStreaming)

-(void)writeOnByteStream:(MPWByteStream*)aStream
{
    [self flattenStructureOntoStream:aStream];
}

-(void)appendBytes:(const void*)bytes length:(long)len
{
    //---	method used by both MPWStream and NSDPSContext
    id newData = [[NSData alloc] initWithBytes:bytes length:len];
    [(MPWStream*)self writeData:newData];
    [newData release];
}


@end

@implementation NSNull(ByteStreaming)

-(void)writeOnByteStream:aStream
{
	[aStream writeNull];
}

@end


@implementation NSData(ByteStreaming)

-(void)writeOnByteStream:(MPWByteStream*)aStream
{
    [aStream appendBytes:[self bytes] length:[self length]];
}

-(long)targetLength
{
    return [self length];
}


-(void)flush
{
}
@end

@implementation NSString(ByteStreaming)

-(void)writeOnByteStream:(MPWByteStream*)aStream
{
	[aStream writeString:self];
//    [aStream appendBytes:[self lossyCString] length:[self length]];
}

-(void)flush
{
}

-(long)targetLength
{
    return [self length];
}

@end

@implementation NSMutableString(ByteStreamTarget)

-(void)appendBytes:(const void*)bytes length:(long)len
{
#if Darwin || TARGET_OS_IPHONE || TARGET_OS_MAC
    [self appendFormat:@"%.*s",(int)len,bytes];
#else
	[self appendString:[NSString stringWithCString:bytes length:len]];
#endif
}

@end

@implementation MPWForwardingTarget

idAccessor( target, setTarget )
scalarAccessor( SEL, selector, setSelector )

-initWithTarget:newTarget selector:(SEL)newSelector
{
	self=[super init];
	[self setTarget:newTarget];
	[self setSelector:newSelector];
	return self;
}

+forwarderWithTarget:data selector:(SEL)newSelector
{
	return [[[self alloc] initWithTarget:data selector:newSelector] autorelease];
}

-(void)appendBytes:(const void*)bytes length:(long)len
{
	[[self target] performSelector:[self selector] withObject:[NSData dataWithBytes:bytes length:len]];
}

-(void)dealloc
{
	[target release];
	[super dealloc];
}



@end


@implementation MPWStdioTarget

static id Stdout=nil,Stderr=nil;

idAccessor( tempFileName, setTempFileName )
idAccessor( finalFileName, setFinalFileName )

-initWithFile:(FILE*)newFile close:(BOOL)shouldClose
{
    if ( self=[super init] ) {
        outfile=newFile;
        doClose=shouldClose;
    }
    return self;
}

-initWithFile:(FILE*)newFile
{
    return [self initWithFile:newFile close:YES];
}

+Stdout
{
    if (!Stdout) {
        Stdout=[[self alloc] initWithFile:stdout close:NO];
    }
    return Stdout;
}

+Stderr
{
    if (!Stderr) {
        Stderr=[[self alloc] initWithFile:stderr close:NO];
    }
    return Stderr;
}

+fileTarget:(FILE*)newFile
{
    return [[[self alloc] initWithFile:newFile] autorelease];
}

+fileNameTarget:(NSString*)filename mode:(NSString*)mode atomically:(BOOL)atomic
{
    id tempName = filename;
    id target;
	FILE *f;
    if ( atomic ) {
        tempName=[filename stringByAppendingString:@"~"];
    }
	f= fopen( [tempName fileSystemRepresentation] ,[mode fileSystemRepresentation] );
	if ( !f ) {
		[NSException raise:@"openfailure" format:@"%@ failed to open %@, error: %s",
			[self class],tempName,strerror(errno)];
	}
//  setbuffer( f, NULL, 128 * 1024 );
    target = [self fileTarget:f];
    if ( atomic ) {
        [target setFinalFileName:filename];
        [target setTempFileName:tempName];
    }
    return target;
}

+fileNameTarget:(NSString*)filename mode:(NSString*)mode
{
    return [self fileNameTarget:filename mode:mode atomically:YES];
}


-(void)appendBytes:(const void*)bytes length:(unsigned long)len
{
//    NSAssert2( outfile != NULL,@"outfile is NULL, %@=%p",[self class],self );
    fwrite( bytes, len,1,outfile );
}

-(NSUInteger)length
{
    return ftell( outfile );
}

-(long)targetLength
{
    return [self length];
}

-(void)flush
{
    fflush( outfile );
}
char hi_crash;
-(void)closeLocal
{
    if ( outfile ) {
        fclose(outfile);
        if ( finalFileName && tempFileName ) {
			NSFileManager* fileManager=[NSFileManager defaultManager];
			[fileManager removeItemAtPath:finalFileName error:nil];
			[fileManager moveItemAtPath:tempFileName toPath:finalFileName error:nil];
            [self setFinalFileName:nil];
            [self setTempFileName:nil];
        }
    }
    outfile=NULL;
}

-(void)close
{
    [self closeLocal];
}

-(void)close:(int)n
{
    [self closeLocal];
}

-(void)dealloc
{
    if ( doClose ) {
        [self close];
    }
    [tempFileName release];
    [finalFileName release];
    [super dealloc];
}

@end

@implementation MPWFileDescriptorTarget

intAccessor( fd, setFd )

-initWithFd:(int)newFd
{
	self=[super init];
	[self setFd:newFd];
	return self;
}

+fd:(int)newFd
{
	return [[[self alloc] initWithFd:newFd] autorelease];
}

-(void)appendBytes:(const void *)bytes length:(unsigned long)len
{
	write(fd, bytes, len );
}

@end


@implementation MPWNullTarget


-(void)appendBytes:(const void *)bytes length:(unsigned long)len
{
}

@end

#import "NSStringAdditions.h"

@implementation MPWByteStream(testing)


+(void)testPrintDictionary
{
    MPWByteStream* stream=[self stringStream];
	NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:@"1",@"first",@"2",@"second",nil];
    [stream writeObject:dict];
    [stream close];
	IDEXPECT([stream result],@"{\n    first = 1;\n    second = 2;\n}",@" dict ");
}

+(void)testStdoutIsUnique
{
	INTEXPECT( [MPWByteStream Stdout], [MPWByteStream Stdout], @"Stdout" );
}

+(void)testIndent
{
    MPWByteStream* stream=[self stringStream];
	[stream writeIndent];
	IDEXPECT( [stream result], @"",@"zero indent");
}
+(void)testNumberPrint
{
    MPWByteStream* stream=[self stringStream];
	[stream print:[NSNumber numberWithInt:42]];
    [stream close];
	IDEXPECT([self makeString:[NSNumber numberWithInt:42]],@"42",@" print: NSNumber ");
}

+(void)testMakeString
{
	IDEXPECT([self makeString:[NSNumber numberWithInt:42]],@"42",@" print: NSNumber ");
}



+(void)testFloatPrintf
{
    MPWByteStream* stream=[self streamWithTarget:[NSMutableString string]];
    [stream printf:@"%g",1.0];
    [stream close];
    //    NSLog(@"stream target='%@'",[stream target]);
    NSAssert1( [[stream target] isEqual:@"1"],@"Writing 1.0 to stream produces '%@'",[stream target]);
}


+(void)testFloatPrintFormatted
{
    MPWByteStream* stream=[self streamWithTarget:[NSMutableString string]];
    [stream printFormat:@"%g",1.0];
    [stream close];
    //    NSLog(@"stream target='%@'",[stream target]);
    NSAssert1( [[stream target] isEqual:@"1"],@"Writing 1.0 to stream produces '%@'",[stream target]);
}

+(void)testPrintLineObject
{
    MPWByteStream* stream=[self streamWithTarget:[NSMutableString string]];
    [stream printLine:@"%@",@(1.0)];
    [stream close];
    //    NSLog(@"stream target='%@'",[stream target]);
    NSAssert1( [[stream target] isEqual:@"1\n"],@"Writing 1.0 to stream produces '%@'",[stream target]);
}



+(void)testBasicWritingToNSData
{
	MPWByteStream *stream=[self stream];
	[stream print:@"Hello World"];
	[stream close];
	NSData *result=[stream target];
//	INTEXPECT( [result length], 11 , @"hello world len");
	IDEXPECT( [result stringValue], @"Hello World", @"hello world ");
}

+(void)testBasicWritingToNSDataViaForwarder
{
	NSMutableData *data=[NSMutableData data];
	MPWByteStream *stream=[self streamWithTarget:[MPWForwardingTarget forwarderWithTarget:data selector:@selector(appendData:)]];
	[stream print:@"Hello World"];
	[stream close];
	NSData *result=[[stream target] target];
//	INTEXPECT( [result length], 11 , @"hello world len");
	IDEXPECT( [result stringValue], @"Hello World", @"hello world ");
}

+(void)testUnicodeUTF8
{
    MPWByteStream *s=[self stream];
    unichar pichar=960;
    NSString *pistring=[NSString stringWithCharacters:&pichar length:1];
    [s outputString:pistring];
    NSData *encodedResult=[s target];
    const unsigned char *bytes=[encodedResult bytes];
    INTEXPECT([encodedResult length], 2, @"length of pi in utf-8");
    INTEXPECT(bytes[0], 0xcf, @"pi as utf-8 first byte");
    INTEXPECT(bytes[1], 0x80, @"pi as utf-8 second byte");
}


+testSelectors
{
    return @[
			@"testFloatPrintf",
			@"testFloatPrintFormatted",
			@"testNumberPrint",
            @"testPrintLineObject",
            //			@"testPrintDictionary",
			@"testStdoutIsUnique",
			@"testBasicWritingToNSData",
			@"testIndent",
			@"testBasicWritingToNSDataViaForwarder",
            @"testUnicodeUTF8",
            ];
}


@end

#if 0 && !Darwin && !TARGET_OS_IPHONE
@implementation NSString(lossyCString)

-(const char*)lossyCString
{
	return [self cString];
}
@end
#endif
