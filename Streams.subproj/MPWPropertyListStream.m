/* MPWPropertyListStream.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.


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

#import <objc/message.h>

#import "MPWPropertyListStream.h"



@implementation NSObject(PropertyListStreaming)

-(void)writeOnPropertyList:(MPWByteStream*)aStream
{
    [self writeOnByteStream:aStream];
}

@end

@implementation MPWPropertyListStream


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
    [self writeString:aKey];
}

-(void)writeDictionaryLikeObject:anObject withContentBlock:(WriterBlock)contentBlock
{
    [self beginDictionary];
    @try {
        contentBlock(self,anObject);
    } @finally {
        [self endDictionary];
    }
}

-(void)writeDictionary:(NSDictionary *)dict
{
    [self writeDictionaryLikeObject:dict withContentBlock:^(MPWStream *writer, id aDict){
        [aDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
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
    if (!strRep) {
        strRep=NSSelectorFromString(@"quotedStringRepresentation");
    }
    if ( strRep) {
        id temp=((IMP0)objc_msgSend)( anObject, strRep);
        [self outputString:temp];
    }
}

-(void)writeEnumerator:(NSEnumerator*)e spacer:spacer
{
    BOOL first=YES;
    id nextObject;
    while (nil!=(nextObject=[e nextObject])) {
        [self writeIndent];
        if ( !first ) {
			[self appendBytes:"," length:2];
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

-(void)writeOnPropertyList:(MPWPropertyListStream*)aStream
{
    [aStream writeString:self ];
}

@end

@implementation NSNumber(PropertyListStreaming)


-(void)writeOnPropertyList:(MPWPropertyListStream*)aStream
{
    Class boolClass = nil;
    if ( boolClass == nil) {
        boolClass=[@YES class];
    }
    
//	if ( [NSStringFromClass([self class]) rangeOfString:@"Boolean"].length > 0)  {
    if ( [self class] == boolClass)  {
		[aStream writeBoolean:[self boolValue]];
	} else if ( CFNumberIsFloatType( (CFNumberRef)self ) ) {
		[aStream writeFloat:[self doubleValue]];
	} else {
		[aStream writeInteger:[self intValue]];
	}
	
}


@end


#import "DebugMacros.h"

@implementation MPWPropertyListStream(testing)


+_testStream {
	return [self streamWithTarget:[NSMutableString string]];
}

+_encode:anObject
{
	MPWPropertyListStream *writer=[self _testStream];
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
	IDEXPECT( [self _encode:[NSNumber numberWithInt:42]], @"42", @"42");
	IDEXPECT( [self _encode:[NSNumber numberWithInt:1]], @"1", @"1");
	IDEXPECT( [self _encode:[NSNumber numberWithInt:0]], @"0", @"0");
	IDEXPECT( [self _encode:[NSNumber numberWithInt:-1]], @"-1", @"1");
}


+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testWriteString",
			@"testWriteArray",
//			@"testWriteLiterals",
			@"testWriteIntegers",
			@"testWriteDict",
//			@"testEscapeStrings",
//			@"testUnicodeEscapes",
			nil];
}

@end

