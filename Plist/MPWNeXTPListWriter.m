/* MPWNeXTPListWriter.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/

#import <objc/message.h>

#import <MPWNeXTPListWriter.h>



@implementation NSObject(PropertyListStreaming)

-(void)writeOnPropertyList:(MPWByteStream*)aStream
{
    [self writeOnByteStream:aStream];
}

@end

@implementation MPWNeXTPListWriter


-(void)beginArray
{
    [self appendBytes:"( " length:2];
}

-(void)endArray
{
    [self appendBytes:") " length:2];
}

-(void)beginDictionary
{
    [self appendBytes:"{ " length:2];
}

-(void)endDictionary
{
    [self appendBytes:"} " length:2];
}

-(void)writeKey:(NSString*)aKey
{
    [self writeObject:aKey];
    [self appendBytes:" = " length:3];
}

-(void)writeDictionaryLikeObject:anObject withContentBlock:(void (^)(MPWNeXTPListWriter* writer))contentBlock
{
    currentFirstElement++;
    firstElementOfDict[currentFirstElement]=YES;
    [self beginDictionary];
    @try {
        contentBlock(self);
    } @finally {
        currentFirstElement--;
        [self endDictionary];
    }
}

-(void)writeDictionary:(NSDictionary *)dict
{
    [self writeDictionaryLikeObject:dict withContentBlock:^(MPWWriteStream *writer){
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            [self writeObject:obj forKey:key];
        }];
    }];
}


-(void)writeInteger:(long)anInteger
{
    [self printf:@"%d",anInteger];
}

-(void)writeFloat:(float)aFloat
{
    [self printf:@"%g",aFloat];
}

-(void)writeBoolean:(BOOL)truthValue
{
	if ( truthValue ) {
		[self appendBytes:"true" length:4];
	} else {
		[self appendBytes:"false" length:5];
	}
}

-(void)writeString:(NSString*)anObject
{
    // FIXME:  not really allowed to access this
    static SEL strRep=NULL;
    static BOOL avail=NO;
    if (!strRep) {
        strRep=NSSelectorFromString(@"quotedStringRepresentation");
        avail=[anObject respondsToSelector:strRep];
    }
    if ( strRep && avail) {
        anObject=((IMP0)objc_msgSend)( anObject, strRep);
        [self outputString:anObject];
    } else {
        [self outputString:@"\""];
        [self outputString:anObject];
        [self outputString:@"\""];
    }
}

-(void)writeEnumerator:(NSEnumerator*)e spacer:spacer
{
    BOOL first=YES;
    id nextObject;
    while (nil!=(nextObject=[e nextObject])) {
        [self writeIndent];
        if ( !first ) {
			[self appendBytes:"," length:1];
        }
        [self writeObject:nextObject];
		first=NO;
//        [self basicWriteString:@"\n"];
    }
}

-(void)writeArrayContent:(NSArray*)array
{
    [super writeArray:array];
}

-(void)writeArray:(NSArray*)anArray
{
//	NSLog(@" =========== plist stream write array: %@",anArray);
	[self beginArray];
    [self writeArrayContent:anArray];
	[self endArray];
}

-(void)writeEnumerator:e
{
    [self writeEnumerator:e spacer:@","];
}


-(SEL)streamWriterMessage
{
    return @selector(writeOnPropertyList:);
}


@end
@implementation NSString(PropertyListStreaming)

-(void)writeOnPropertyList:(MPWNeXTPListWriter*)aStream
{
    [aStream writeString:self ];
}

@end

@implementation NSNumber(PropertyListStreaming)


-(void)writeOnPropertyList:(MPWNeXTPListWriter*)aStream
{
    Class boolClass = nil;
    if ( boolClass == nil) {
        boolClass=[@YES class];
    }
    
    if ( [self class] == boolClass)  {
		[aStream writeBoolean:[self boolValue]];
    } else {
        const char *type=[self objCType];
        if ( type && (type[0]=='f' || type[0]=='d') ) {
            [aStream writeFloat:[self doubleValue]];
        } else {
            [aStream writeInteger:[self intValue]];
        }
	}
	
}


@end


#import "DebugMacros.h"

@implementation MPWNeXTPListWriter(testing)


+_testStream {
	return [self streamWithTarget:[NSMutableString string]];
}

+_encode:anObject
{
	MPWNeXTPListWriter *writer=[self _testStream];
	//	NSLog(@"stream: %@",writer);
	[writer writeObject:anObject];
	[writer close];
	return [writer target];
}


+(void)testWriteString
{
	IDEXPECT( [self _encode:@"hello world"], @"\"hello world\"", @"string encode");
}

+(void)testWriteArray
{
	IDEXPECT( ([self _encode:[NSArray arrayWithObjects:@"hello",@"world",nil]]), 
			 @"( \"hello\",\"world\") ", @"array encode");
}

+(void)testWriteDict
{
	NSString *expectedEncoding= @"{ \"key\" = \"value\";\n\"key1\" = \"value1\";\n} ";
	NSString *actualEncoding=[self _encode:[NSDictionary dictionaryWithObjectsAndKeys:@"value",@"key",
											@"value1",@"key1",nil ]];
	//	INTEXPECT( [actualEncoding length], [expectedEncoding length], @"lengths");
	
	IDEXPECT( actualEncoding, expectedEncoding, @"dict encode");
}

+(void)testWriteIntegers
{
    IDEXPECT( [self _encode:@(42)], @"42", @"42");
    IDEXPECT( [self _encode:[NSNumber numberWithInt:1]], @"1", @"1");
    IDEXPECT( [self _encode:[NSNumber numberWithInt:0]], @"0", @"0");
    IDEXPECT( [self _encode:[NSNumber numberWithInt:-1]], @"-1", @"1");
}

+(void)testWriteDictWithIntegerKeys
{
    NSDictionary *d=@{ @(157): @"Hello", @(2): @"World"};
    IDEXPECT( [self _encode:d], @"{ 157 = \"Hello\";\n2 = \"World\";\n} ", @"dict with int keys");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testWriteString",
            @"testWriteArray",
			@"testWriteIntegers",
			@"testWriteDict",
            @"testWriteDictWithIntegerKeys",
//			@"testEscapeStrings",
//			@"testUnicodeEscapes",
			nil];
}

@end

