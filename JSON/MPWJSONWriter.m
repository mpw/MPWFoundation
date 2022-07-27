//
//  MPWJSONWriter.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 12/30/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWJSONWriter.h"
#import "MPWPropertyBinding.h"
#import <objc/runtime.h>
#import "NSObjectFiltering.h"
#import "NSObjectAdditions.h"

@implementation MPWJSONWriter

-(void)writeKey:(NSString*)aKey
{
    [self writeString:aKey];
    [self appendBytes:":" length:1];
}

#define INTBUFLEN 64

typedef struct {
    char buf[INTBUFLEN];
} intbuf;

static inline char *ltoa( long value, intbuf *buf )
{
    char *buffer=buf->buf;
    int offset=INTBUFLEN/2;
    buffer[offset]=0;
    do {
        long next=value/10;
        long digit=value - (next*10)+'0';
        buffer[--offset]=digit;
        value=next;
    } while (value);
    return buffer+offset;
}


//static inline long writeCStringKey( char *buffer, char *key, BOOL *firstPtr)


static inline long writeKey( char *buffer, NSString *key, BOOL *firstPtr)
{
    char *ptr=buffer;
    const char *keyptr=CFStringGetCStringPtr( (CFStringRef)key, kCFStringEncodingUTF8);
    NSUInteger keylen=CFStringGetLength( (CFStringRef)key);
    if (!keyptr){
        long maxLen=[key maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        keyptr=alloca(maxLen+1);
        [key getBytes:(void*)keyptr maxLength:maxLen usedLength:&keylen encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, keylen) remainingRange:NULL];
    }
    if ( *firstPtr ) {
        *firstPtr=NO;
    } else {
        *ptr++ = ',';
    }
    *ptr++ = '"';
    memcpy( ptr, keyptr, keylen);
    ptr+=keylen;
    *ptr++ ='"';
    *ptr++ =':';
    ptr[1]=0;
    return ptr-buffer;
}

-(void)writeString:aString forKey:(NSString*)aKey
{
    char buffer[1000];
    long len=writeKey(buffer, aKey, firstElementOfDict + currentFirstElement);
    [self appendBytes:buffer length:len];
//    [self appendBytes:"\":" length:2];
    [self writeObject:aString];
}

-(void)writeObject:(id)anObject forKey:(id)aKey
{
    char buffer[1000];
    long len=writeKey(buffer, aKey, firstElementOfDict + currentFirstElement);
    [self appendBytes:buffer length:len];
//    [self writeKey:aKey];
    [self writeObject:anObject];
}

-(void)writeInteger:(long)number forKey:(NSString*)aKey
{
    char buffer[1000];
    long len=writeKey(buffer, aKey, firstElementOfDict + currentFirstElement);
    char *ptr=buffer+len;
    intbuf ibuf;
    char *s=ltoa(number, &ibuf);
    long ilen=strlen(s);
    memcpy( ptr, s, ilen);
    ptr+=ilen;
    TARGET_APPEND(buffer, ptr-buffer);
//    [self appendBytes:buffer length:ptr-buffer];
}

-(void)beginArray
{
    TARGET_APPEND("[", 1);
}

-(void)endArray
{
    TARGET_APPEND("]", 1);
}

-(void)beginDictionary
{
    TARGET_APPEND("{", 1);
}

-(void)endDictionary
{
    TARGET_APPEND("}", 1);
}

-(void)writeArray:(NSArray*)anArray
{
//	NSLog(@"==== JSONriter writeArray: %@",anArray);
    [self beginArray];
//	[self indent];
    [self writeArrayContent:anArray];
//	[self outdent];
	[self endArray];
}

//-(void)writeDictionary:(NSDictionary *)dict
//{
//	BOOL first=YES;
//	[self beginDictionary];
//	for ( NSString *key in [dict allKeys] ) {
//		if ( first ) {
//			first=NO;
//		} else {
//			[self appendBytes:", " length:2];	
//		}
//		[self writeObject:[dict objectForKey:key] forKey:key];
//	}
//	[self endDictionary];
//}

-(void)writeString:(NSString*)anObject
{
    const char *buffer=NULL;
    char curchar;
    NSUInteger len=[anObject length];
//	NSLog(@"==== JSONriter writeString: %@",anObject);
    TARGET_APPEND("\"", 1);
    buffer=CFStringGetCStringPtr((CFStringRef)anObject, kCFStringEncodingUTF8);
    if ( buffer ) {
//        NSLog(@"got buffer: %p",buffer);
    } else {
        long maxLen= [anObject maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        buffer=alloca(maxLen+2);
//        NSLog(@"alloca buffer: %p",buffer);
//        NSAssert(buffer, @"buffer");
        [anObject getBytes:(void*)buffer maxLength:maxLen+1 usedLength:&len encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, len) remainingRange:NULL];
        ((char*)buffer)[len]=0;
//        NSLog(@"got bytes: %d",success);
//        NSAssert(success,@"got bytes");
//        [anObject getCString:buffer maxLength:maxLen encoding:NSUTF8StringEncoding];
    }
    const char *endptr=buffer+len;
    const char *rest=buffer;
    const char *cur=rest;
//	NSLog(@"length of UTF8: %d",strlen(buffer));
	while ( (curchar = *cur) && cur < endptr ) {
        
        while (  cur < endptr && (curchar > '0')  && (curchar != '\\')) {
            cur++;
            curchar=*cur;
        }
        if (curchar==' ') {
            cur++;
            continue;
        }
        if (curchar==0) {
            break;
        }
        
		char *escapeSequence=NULL;
		char unicodeEscapeBuf[16];
		switch (curchar) {
			case '\\':
				escapeSequence="\\\\";
				break;
			case '"':
				escapeSequence="\\\"";
				break;
			case '\n':
				escapeSequence="\\n";
				break;
			case '\t':
				escapeSequence="\\t";
				break;
			case '\r':
				escapeSequence="\\r";
				break;
			default:
				
				if ( curchar < 32 ) {
					snprintf( unicodeEscapeBuf, 8,"\\u00%02x",*cur);
					escapeSequence=unicodeEscapeBuf;
				}
				break;
		}
		if ( escapeSequence ) {
            TARGET_APPEND((char*)rest, cur-rest);
            TARGET_APPEND(escapeSequence, strlen(escapeSequence));
			cur++;
			rest=cur;
			
		} else {
			cur++;
		}
	}
    TARGET_APPEND((char*)rest,endptr-rest);
    TARGET_APPEND("\"", 1);
}

-(SEL)streamWriterMessage
{
	return @selector(writeOnJSONStream:);
}

-(void)writeNull
{
	[self appendBytes:"null" length:4];
}

-(void)writeInteger:(long)number
{
	[self printf:@"%d",number];
}


-(void)writeFloat:(float)number
{
	[self printf:@"%g",number];
}


//------------



@end


@implementation NSObject(jsonWriting)

-(void)writeOnJSONStream:(MPWJSONWriter*)aStream
{
	[self writeOnPropertyList:aStream];
}


@end

#import <MPWFoundation/DebugMacros.h>

@interface MPWJSONWriterTestClass : NSObject

@property (nonatomic, assign) int a,b;
@property (nonatomic, strong) NSString *c;

@end
@implementation MPWJSONWriterTestClass

-(void)dealloc
{
    [_c release];
    [super dealloc];
}

@end

@interface MPWJSONWriterTestClassWithCoder : NSObject

@property (nonatomic, assign) int a,b;
@property (nonatomic, strong) NSString *c;

@end
@implementation MPWJSONWriterTestClassWithCoder

-(void)writeOnJSONStream:(MPWJSONWriter *)aStream
{
    [aStream writeDictionaryLikeObject:self withContentBlock:^(MPWJSONWriterTestClassWithCoder* object, MPWJSONWriter *writer) {
        [writer writeInteger:object.a forKey:@"a"];
    }];
}

-(void)dealloc
{
    [_c release];
    [super dealloc];
}

@end

@implementation NSObject(asJSON)

-(NSData*)asJSON
{
    return [MPWJSONWriter process:self];
}

@end

@implementation MPWJSONWriter(testing)

+(void)testWriteArray
{
	IDEXPECT( ([self _encode:[NSArray arrayWithObjects:@"hello",@"world",nil]]), 
			 @"[\"hello\",\"world\"]", @"array encode" );
}

+(void)testWriteDict
{
	NSString *expectedEncoding= @"{\"key\":\"value\",\"key1\":\"value1\"}";
	NSString *actualEncoding=[self _encode:[NSDictionary dictionaryWithObjectsAndKeys:@"value",@"key",
											@"value1",@"key1",nil ]];
//	INTEXPECT( [actualEncoding length], [expectedEncoding length], @"lengths");
	
	IDEXPECT( actualEncoding, expectedEncoding, @"dict encode");
}

+(void)testWriteLiterals
{
    NSLog(@"bool %@ / %@",[NSNumber numberWithBool:YES],[[NSNumber numberWithBool:YES] class]);
	IDEXPECT( [self _encode:[NSNumber numberWithBool:YES]], @"true", @"true");
	IDEXPECT( [self _encode:[NSNumber numberWithBool:NO]], @"false", @"false");
	IDEXPECT( [self _encode:[NSNull null]], @"null", @"null");
}


+(void)testEscapeStrings
{
	IDEXPECT( [self _encode:@"\""], @"\"\\\"\"", @"quote is escaped");
	IDEXPECT( [self _encode:@"\n"], @"\"\\n\"", @"newline is escaped");
	IDEXPECT( [self _encode:@"\r"], @"\"\\r\"", @"return is escaped");
	IDEXPECT( [self _encode:@"\t"], @"\"\\t\"", @"tab is escaped");
    IDEXPECT( [self _encode:@"\\"], @"\"\\\\\"", @"backslash is escaped");
    IDEXPECT( [self _encode:@"hello world\\\n"], @"\"hello world\\\\\\n\"", @"combined escapes");
}


+(void)testUnicodeEscapes
{
	unichar thechar=1;
	IDEXPECT( [self _encode:[NSString stringWithCharacters:&thechar length:1]], @"\"\\u0001\"", @"ASCII 1 is Unicode escaped");
	thechar=2;
	IDEXPECT( [self _encode:[NSString stringWithCharacters:&thechar length:1]], @"\"\\u0002\"", @"ASCII 2 is Unicode escaped");
	thechar=27;
	IDEXPECT( [self _encode:[NSString stringWithCharacters:&thechar length:1]], @"\"\\u001b\"", @"ASCII 27 is Unicode escaped");
}

+(instancetype)_testStream {
    return [self streamWithTarget:[NSMutableString string]];
}

+(void)testCreateSerializationMethod
{
    MPWJSONWriterTestClass *obj=[[MPWJSONWriterTestClass new] autorelease];
    MPWJSONWriter *s = [self _testStream];
    obj.a = 41;
    obj.b = 12;
    obj.c = @"Test String";
    [s createEncoderMethodForClass:obj.class];
    [s writeObject:obj];
    IDEXPECT([s target],@"{\"a\":41,\"b\":12,\"c\":\"Test String\"}",@"encoded");
}

+(void)testCreatingSerializationMethodDoesNotOverrideExisting
{
    MPWJSONWriterTestClassWithCoder *obj=[[MPWJSONWriterTestClassWithCoder new] autorelease];
    MPWJSONWriter *s = [self _testStream];
    obj.a = 41;
    obj.b = 12;
    obj.c = @"Test String";
    [s createEncoderMethodForClass:obj.class];
    [s writeObject:obj];
    IDEXPECT([s target],@"{\"a\":41}",@"encoded");
}

+(NSArray*)testSelectors {
	return [NSArray arrayWithObjects:
			@"testWriteString",
			@"testWriteArray",
			@"testWriteLiterals",
			@"testWriteIntegers",
			@"testWriteDict",
			@"testEscapeStrings",
			@"testUnicodeEscapes",
            @"testCreateSerializationMethod",
            @"testCreatingSerializationMethodDoesNotOverrideExisting",

			nil];
}

@end
