/* MPWByteStream.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWByteStream.h>
#import "bytecoding.h"
#import "DebugMacros.h"
#import "MPWDictStore.h"
#import "MPWIgnoreUnknownTrampoline.h"
#include <fcntl.h>
#include <unistd.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import "NSNil.h"

@interface NSString(fastCString)

-( char*)_fastCStringContents:(BOOL)blah;

@end

@interface MPWNullTarget : NSObject

@end


@interface MPWAbstractFileTarget : NSObject
{
    BOOL doClose;
    NSString*    tempFileName;
    NSString*    finalFileName;
}
+fileNameTarget:(NSString*)fileName mode:(NSString*)mode;
+fileNameTarget:(NSString*)filename mode:(NSString*)mode atomically:(BOOL)atomic;

@end

@interface MPWStdioTarget : MPWAbstractFileTarget
{
    FILE *outfile;
}

+Stdout;
+Stderr;
+fileTarget:(FILE*)newFile;
-initWithFile:(FILE*)newFile;

@end

@interface MPWFileDescriptorTarget : MPWAbstractFileTarget
{
	int	fd;
}

-initWithFd:(int)newFd;
+fd:(int)newFd;

@end

#define LARGEBUFSIZE  (1024*1024)

@interface MPWFileTarget : MPWFileDescriptorTarget
{
    int bufferSize;
    char buffer[LARGEBUFSIZE];
    int  written;
}

-(int)bufferSize;
-(void)setBufferSize:(int)newSize;

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
    alreadySeen = [[NSMutableSet alloc] init];

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

#if GS_API_LATEST
static void atexit_b( void *a ) {}
#endif

+Stdout
{
	static id Stdout=nil;
	if ( !Stdout ) {
		Stdout = [[self fd:1] retain];
        atexit_b( ^{ [Stdout close]; });
	}
	return Stdout;
}

+Stderr
{
	static id Stderr=nil;
	if ( !Stderr ) {
        Stderr = [[self fd:2] retain];
        atexit_b( ^{ [Stderr close]; });
	}
	return Stderr;
}

+fd:(int)fd
{
    return [self streamWithTarget:isatty(fd) ? [MPWFileDescriptorTarget fd:fd] : [MPWFileTarget fd:fd]];
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


+fileName:(NSString*)fileName mode:(NSString*)mode atomically:(BOOL)atomic
{
    return [self streamWithTarget:[MPWFileTarget fileNameTarget:fileName mode:mode atomically:atomic]];
}

+fileName:(NSString*)fileName mode:(NSString*)mode
{
    return [self fileName:fileName mode:mode atomically:YES];
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

#if GS_API_LATEST
-(void)outputString:(NSString*)aString
{
    @autoreleasepool {
        NSData *d=[aString asData];
        TARGET_APPEND( [d bytes],[d length] );
    }
}
#else
-(void)outputString:(NSString*)aString
{
#define MAXLEN 8192
    const char *keyptr=CFStringGetCStringPtr( (CFStringRef)aString, kCFStringEncodingUTF8);
    if ( keyptr) {
        NSUInteger keylen=CFStringGetLength( (CFStringRef)aString);
        TARGET_APPEND( (char*)keyptr, keylen);
    } else {
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

}
#endif
-(void)writeString:(NSString*)string
{
    [self outputString:string];
}

-(void)writeNullTerminatedString:(NSString*)string
{
    [self writeString:string];
    [self appendBytes:"" length:1];
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

-(NSData*)processObject:anObject
{
    if (!anObject || [anObject isNil]) {
        return nil;
    }
    NSMutableData *data=[NSMutableData data];
    [self setByteTarget:data];
    [self writeObject:anObject];
    return [self byteTarget];
}

-(long)targetLength
{
    return [(MPWByteStream*)self.target targetLength];
}

-(void)writeKey:(NSString*)aKey
{
    [self writeString:aKey];
    [self appendBytes:": " length:2];
}


-(void)beginObject:anObject
{
    FORWARDCHARS("<");
    const char *className=object_getClassName(anObject);
    TARGET_APPEND( (char*)className, strlen(className) );
    FORWARDCHARS(":");
//    [self printFormat:@"<%@:%p ",[anObject class],anObject];
}

-(void)endObject:anObject
{
    FORWARDCHARS(">");
}


#if 0
-(void)writeObject:anObject sender:sender
{
    @autoreleasepool {
        NSValue *p=[NSValue valueWithPointer:anObject];
        if ( ![alreadySeen containsObject:p]) {
            [alreadySeen addObject:p];
            [super writeObject:anObject sender:sender];
            [alreadySeen removeObject:p];
        } else {
            [self printFormat:@"<Already seen: %@:%p>",[anObject class],anObject];
        }
    }

}
#endif


-(void)writeObject:anObject forKey:aKey
{
    [self writeIndent];
    [self writeKey:aKey];
    [self writeObject:anObject ?: @"(null)"];
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


-(void)writeInterpolatedString:(NSString*)s withEnvironment:(MPWAbstractStore*)env
{
//    NSLog(@"writeInterpolatedString: %@ withEnvironment: %@",s,env);
    long curIndex=0;
    long maxIndex=[s length];
    while (curIndex < maxIndex) {
    
        NSRange leftBrace=[s rangeOfString:@"{"
                                   options:0
                                     range:NSMakeRange(curIndex,maxIndex-curIndex)];
        if ( leftBrace.location == NSNotFound ) {
            break;
        }
        if ( !isascii([s characterAtIndex:leftBrace.location+1]) ) {
            curIndex=leftBrace.location+1;
            continue;
        }
        NSRange rightBrace=[s rangeOfString:@"}"
                                    options:0
                                      range:NSMakeRange(curIndex,maxIndex-curIndex)];
        if ( rightBrace.location == NSNotFound ) {
            break;
        }
        NSRange varRange=NSMakeRange( leftBrace.location+1, rightBrace.location-leftBrace.location-1);
        NSString *varName=[s substringWithRange:varRange];
        [self outputString:[s substringWithRange:NSMakeRange(curIndex,leftBrace.location-curIndex)]];
//        NSLog(@"environment: %@",env);
//        NSLog(@"varName: %@",varName);
        id reference = [env referenceForPath:varName];
//        NSLog(@"reference: %@ - %@",[reference schemeName],[reference path]);
//        NSLog(@"will get value");
        id value=[env at:reference];
//        NSLog(@"did get value");
//        NSLog(@"value: %@",value);
        [self writeObject:value];
        curIndex = rightBrace.location+1;
    }
    if ( curIndex <= maxIndex ) {
        [self outputString:[s substringFromIndex:curIndex]];
    }
}


typedef void (^FileBlock)(FILE *f);
//TypeName blockName = ^returnType(parameters) {...};

-(void)withFile:(FileBlock)fileBlock size:(long)size
{
    if ( fileBlock) {
        char *buffer=malloc(size);
        if (@available(macOS 10.13, *)) {
            FILE *f=fmemopen( buffer , size, "w+b");
            if ( f ) {
                fileBlock(f);
                fflush(f);
                long length=ftell(f);
                if (length>0) {
                    [self appendBytes:buffer length:length];
                }
                fclose(f);
            } else {
                @throw [NSException exceptionWithName:@"internal inconsistency" reason:@"fmemopen() returned NULL" userInfo:nil];
            }
        } else {
            @throw [NSException exceptionWithName:@"unsupperted" reason:@"fmemopen() requires 10.13" userInfo:nil];
        }
        free(buffer);
    }
}


-(NSString*)description
{
	return [NSString stringWithFormat:@"<%@/%p: byteTarget %@/%p",[self class],self,[self.target class],byteTarget];
}


-(void)dealloc
{
    [byteTarget release];
    [alreadySeen release];
    [super dealloc];
}

-finalTarget
{
    return [self byteTarget];
}

-(void)closeLocal
{
    [super closeLocal];
    [[byteTarget ifResponds] closeLocal];
}


//typedef void (*IMPVID1)(id, SEL, id);
//
//+(void)initialize
//{
//    SEL superSelector = @selector(flattenStructureOntoStream:);
//    SEL mySelector = @selector(writeOnByteStream:);
//
//    if ( ![self instancesRespondToSelector:mySelector]) {
//        IMP theImp=imp_implementationWithBlock( ^(id blockSelf, id stream ){
//            ((IMPVID1)objc_msgSend)(blockSelf, superSelector , stream); }
//                                               );
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wundeclared-selector"
//        class_addMethod([NSObject class], mySelector, theImp, "v@:@");
//#pragma clang diagnostic pop
//    }
//
//}

@end


@implementation NSObject(ByteAppending)

-(void)writeOnByteStream:aStream
{
    [self flattenStructureOntoStream:aStream];
}


-(void)appendBytes:(const void*)bytes length:(long)len
{
    //---	method used by both MPWWriteStream and NSDPSContext
    id newData = [[NSData alloc] initWithBytes:bytes length:len];
    [(MPWWriteStream*)self writeData:newData];
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
    [self appendFormat:@"%.*s",(int)len,(char*)bytes];
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

@implementation MPWAbstractFileTarget

objectAccessor(NSString*, tempFileName, setTempFileName )
objectAccessor(NSString*, finalFileName, setFinalFileName )

+(instancetype)fileNameTarget:(NSString*)filename mode:(NSString*)mode atomically:(BOOL)atomic
{
    NSString* tempName = filename;
    MPWAbstractFileTarget* target;
    if ( atomic ) {
        tempName=[filename stringByAppendingString:@"~"];
    }
//    if ( !f ) {
//        [NSException raise:@"openfailure" format:@"%@ failed to open %@, error: %s",
//         [self class],tempName,strerror(errno)];
//    }
    //  setbuffer( f, NULL, 128 * 1024 );
    target = [self fileNameTarget:tempName mode:mode];
    if ( atomic ) {
        [target setFinalFileName:filename];
        [target setTempFileName:tempName];
    }
    return target;
}

-(void)closefile {}

-(void)closeLocal
{
    [self closefile];
    if ( finalFileName && tempFileName ) {
        NSFileManager* fileManager=[NSFileManager defaultManager];
        [fileManager removeItemAtPath:finalFileName error:NULL];
        [fileManager moveItemAtPath:tempFileName toPath:finalFileName error:NULL];
        [self setFinalFileName:nil];
        [self setTempFileName:nil];
    }
}

-(instancetype)initWithName:(NSString *)name mode:(NSString*)mode
{
    [self release];
    return nil;
}

+(instancetype)fileNameTarget:(NSString*)name mode:(NSString*)mode
{
    return [[[self alloc] initWithName:name mode:mode] autorelease];
}

-(void)flushLocal {}

-(void)flush
{
    [self flushLocal];
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


@implementation MPWStdioTarget

static id Stdout=nil,Stderr=nil;


-(void)closefile
{
    if ( outfile ) {
        fclose(outfile);
        outfile=NULL;
    }
}

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

-(instancetype)initWithName:(NSString*)name mode:(NSString*)mode
{
    return [self initWithFile:fopen( [name fileSystemRepresentation], [mode fileSystemRepresentation])];
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

-(void)flushLocal
{
    fflush( outfile );
}
char hi_crash;


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

-(void)redirectTo:(MPWFileDescriptorTarget*)otherFDTarget
{
    dup2([otherFDTarget fd], [self fd]);
}

-(instancetype)initWithName:(NSString*)name mode:(NSString*)mode // atomically:(BOOL)atomic
{
    return [self initWithFd:open( [name fileSystemRepresentation], O_WRONLY | O_CREAT , S_IRUSR | S_IWUSR)];
}


+fd:(int)newFd
{
	return [[[self alloc] initWithFd:newFd] autorelease];
}

-(void)appendBytes:(const void *)bytes length:(unsigned long)len
{
	write(fd, bytes, len );
}

-(void)closefile
{
    if ( fd >= 0) {
        close(fd);
        fd=-1;
    }
}


@end



@implementation MPWFileTarget

-(int)bufferSize
{
    return bufferSize;
}

-(void)setBufferSize:(int)newSize
{
    bufferSize = MAX(MIN( newSize, LARGEBUFSIZE), 0);
}


-initWithFd:(int)newFd
{
    self=[super initWithFd:newFd];
    [self setBufferSize:LARGEBUFSIZE];
    return self;
}

-(void)flushLocal
{
    if ( written >0 ) {
        [super appendBytes:buffer length:written];
        written=0;
    }
}

-(void)appendBytes:(const void *)bytes length:(unsigned long)len
{
    if ( len + written >= bufferSize) {
        [self flushLocal];
    }
    if ( len > bufferSize) {
        [super appendBytes:bytes length:len];
    } else {
        memcpy( buffer+written, bytes, len);
        written+=len;
    }
}

-(void)closeLocal {
    [self flushLocal];
    [super closeLocal];
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
	NSData *result=(NSData*)[stream target];  // FIXME
//	INTEXPECT( [result length], 11 , @"hello world len");
	IDEXPECT( [result stringValue], @"Hello World", @"hello world ");
}

+(void)testBasicWritingToNSDataViaForwarder
{
	NSMutableData *data=[NSMutableData data];
	MPWByteStream *stream=[self streamWithTarget:[MPWForwardingTarget forwarderWithTarget:data selector:@selector(appendData:)]];
	[stream print:@"Hello World"];
	[stream close];
	NSData *result=(NSData*)[(MPWFilter*)[stream target] target];  // FIXME
//	INTEXPECT( [result length], 11 , @"hello world len");
	IDEXPECT( [result stringValue], @"Hello World", @"hello world ");
}

+(void)testUnicodeUTF8
{
    MPWByteStream *s=[self stream];
    unichar pichar=960;
    NSString *pistring=[NSString stringWithCharacters:&pichar length:1];
    [s outputString:pistring];
    NSData *encodedResult=(NSData*)[s target];   // FIXME
    const unsigned char *bytes=[encodedResult bytes];
    INTEXPECT([encodedResult length], 2, @"length of pi in utf-8");
    INTEXPECT(bytes[0], 0xcf, @"pi as utf-8 first byte");
    INTEXPECT(bytes[1], 0x80, @"pi as utf-8 second byte");
}

+(void)testInterpolateSimpleString
{
    NSMutableString *result=[NSMutableString string];
    MPWByteStream* stream=[self streamWithTarget:result];
    MPWDictStore *store=[MPWDictStore store];
    id ref=[store referenceForPath:@"var"];
    store[ref]=@"World!";
    [stream writeInterpolatedString:@"Hello {var}" withEnvironment:store];
    IDEXPECT(result,@"Hello World!",@"result of interpolating");
}

+(void)testInterpolateStringInMiddle
{
    NSMutableString *result=[NSMutableString string];
    MPWByteStream* stream=[self streamWithTarget:result];
    MPWDictStore *store=[MPWDictStore store];
    id ref=[store referenceForPath:@"var"];
    store[ref]=@"cruel";
    [stream writeInterpolatedString:@"Hello {var} world!" withEnvironment:store];
    IDEXPECT(result,@"Hello cruel world!",@"result of interpolating");
}

+(void)testInterpolateStringWithTwoVars
{
    NSMutableString *result=[NSMutableString string];
    MPWByteStream* stream=[self streamWithTarget:result];
    MPWDictStore *store=[MPWDictStore store];
    id ref1=[store referenceForPath:@"var"];
    id ref2=[store referenceForPath:@"var2"];
    store[ref1]=@"cruel";
    store[ref2]=@"world";
    [stream writeInterpolatedString:@"Hello {var} {var2}!" withEnvironment:store];
    IDEXPECT(result,@"Hello cruel world!",@"result of interpolating");
}

+(void)testAccessViaFILE
{
    MPWByteStream *s=[MPWByteStream stream];
    [s withFile:^(FILE *file){
        fprintf(file,"Hello %d",43);
    } size:100];
    IDEXPECT([[s target] stringValue],@"Hello 43" , @"result of fprintf-ing into the MPWByteStream");
};

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
            @"testInterpolateSimpleString",
            @"testInterpolateStringInMiddle",
            @"testInterpolateStringWithTwoVars",
            @"testAccessViaFILE",
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
