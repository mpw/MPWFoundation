/* NSStringAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "NSStringAdditions.h"
#import <MPWFoundation/DebugMacros.h>
#import "PhoneGeometry.h"

@implementation NSString(Additions)

-(const void*)bytes
{
/*"
    Make #NSString compatible with #NSData.  Returns #{[self cString]}.
"*/
    return [self UTF8String];
}

-(NSString*)stringValue
/*"
    Return #self.
"*/
{
    return self;
}

-(NSData*)asData
/*"
     Returns my cString-data as a #NSData.
"*/
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSArray<NSString*>*)resultsOfCommand
{
    FILE *fin = popen([self UTF8String], "r");
    NSMutableArray<NSString*> *result=[NSMutableArray array];
    if ( fin ) {
        char buffer[16390]="";
        char *fgetsResult;
        do {
            fgetsResult=fgets(buffer, 16384, fin);
            if ( strlen(buffer)) {
                [result addObject:[NSString stringWithUTF8String:buffer]];
            }
        } while (fgetsResult!=NULL);
        pclose(fin);
    }
    return result;

}

-(BOOL)writeToURL:(NSURL*)url options:(long)option error:(NSError**)error
{
    return [[self asData] writeToURL:url options:option error:error];
}

-(NSString*)uniquedByNumberingInPool:(NSSet*)otherStrings
{
    id result=self;
    int number;
    for (number=1; [otherStrings containsObject:result];number++) {
        result=[NSString stringWithFormat:@"%@-%d",self,number];
    }
    return result;
}

-(NSString*)uniquedByNumberingInUpdatingPool:(NSMutableSet*)otherStrings
{
    id result = [self uniquedByNumberingInPool:otherStrings];
    if ( result != self ) {
        [otherStrings addObject:result];
    }
    return result;
}

-at:(NSNumber*)anIndex
{
    return [self substringWithRange:NSMakeRange(anIndex.intValue,1)];
}

+(id)stringWithCharacter:(int)theChar
{
    unichar ch=theChar;
    return [self stringWithCharacters:&ch length:1];
}

-(NSString*)lf
{
    return [self stringByAppendingString:@"\n"];
}

-(NSComparisonResult)numericCompare:other
{
	return [self compare:other options:64];
}

-(int)countOccurencesOfCharacter:(int)c
{
    long count=0,i,len=[self length];
    unichar buf[ len ];
    [self getCharacters:buf];
    for (i=0;i<len;i++) {
        if ( buf[i]==c ) {
            count++;
        }
    }
    return (int)count;
}

-asNumber
{
	if ( [self rangeOfString:@"."].length == 0 ) { 
		return [NSNumber numberWithInt:[self intValue]];
	} else {
		return [NSNumber numberWithFloat:[self floatValue]];
	}
}

-(NSString*)camelCaseString
{
    NSEnumerator *words=[[self componentsSeparatedByString:@" "] objectEnumerator];
    NSMutableString *result=[NSMutableString string];
    [result appendString:[[words nextObject] lowercaseString]];
    for ( NSString *word in words) {
        [result appendString:[word capitalizedString]];
    }
    return result;
}

#ifdef GS_API_LATEST
- (BOOL)getBytes:(nullable void *)buffer maxLength:(NSUInteger)maxBufferCount usedLength:(nullable NSUInteger *)usedBufferCount encoding:(NSStringEncoding)encoding options:(NSStringEncodingConversionOptions)options range:(NSRange)range remainingRange:(nullable NSRangePointer)leftover
{
    BOOL result = [self getCString:buffer maxLength:maxBufferCount encoding:encoding];
    if (result) {
        int len=strlen( buffer);
        if ( usedBufferCount ) {
            *usedBufferCount=len;
        }
        if ( leftover ) {
            *leftover=NSMakeRange(0,0);
        }
    } else {
        if ( usedBufferCount ) {
            *usedBufferCount=0;
        }
        if ( leftover ) {
            *leftover=NSMakeRange(0,0);
        }
    }
    return result;
}
#endif

#if WINDOWS

-(char*)_fastCStringContents:(BOOL)blah
{
	return NULL;
}

#endif


#define COMPARETYPE(type, encoding)  !strcmp( @encode(typeof(type)),encoding)
#define CONVERT(type,encoding,func,ptr)  if ( COMPARETYPE(type,encoding)) { return func( *(type*)ptr ); }
#define CONVERTSIMPLE( encoded, type, format )  case encoded: return [NSString stringWithFormat:@"##type##",*(type*)any];

#if 0

// FIXME:   clang analyzer can't figure out the type-strings
//          and thinks vars are uninitialized (taking tests into account)

NSString *MPWConvertToString( void* any, char *typeencoding ) {
	switch (*typeencoding ) {
		case 'i':
			return [NSString stringWithFormat:@"%d",*(int*)any];
		case 'd':
			return [NSString stringWithFormat:@"%g",*(double*)any];
		case ':':
			return NSStringFromSelector( *(SEL*)any);
		case '@':
			return *(id*)any;
		default:
			CONVERT( NSPoint, typeencoding, NSStringFromPoint, any );
			CONVERT( NSRect, typeencoding, NSStringFromRect, any );
			CONVERT( NSSize, typeencoding, NSStringFromSize, any );
			CONVERT( NSRange, typeencoding, NSStringFromRange, any );
	}
	return [NSString stringWithFormat:@"unknown format %s",typeencoding];
}

#endif




@end

@implementation NSNumber(asNumber)

-asNumber	{ return self; }


@end



@implementation NSData(asPropertyList)

-propertyList
{
    return [NSPropertyListSerialization propertyListWithData:self options:0
                                                      format:NULL error:NULL];
}

-mutablePropertyList
{
    return [NSPropertyListSerialization propertyListWithData:self options:NSPropertyListMutableContainers
                                                      format:NULL error:NULL];
}

@end


@implementation NSMutableString(Additions)

-(instancetype)reinit
{
    [self deleteCharactersInRange:NSMakeRange(0, self.length)];
    return self;
}

@end

@interface NSStringAdditionsTesting : NSObject
@end
@implementation NSStringAdditionsTesting

+(void)testOccurencesOf
{
    INTEXPECT( [@"This is a test string" countOccurencesOfCharacter:'i'],3,@"occurences of");
}

#if 0

+(void)testAnyToString
{
	IDEXPECT( MPWConvertVarToString( 2 ),@"2", @"two");
	IDEXPECT( MPWConvertVarToString( NSMakePoint(2, 3) ),@"{2, 3}", @"2,3");
	IDEXPECT( MPWConvertVarToString( NSMakeRange(1, 2) ),@"{1, 2}", @"1,2");
	IDEXPECT( MPWConvertVarToString( @"asd" ),@"asd", @"2,3");
	IDEXPECT( MPWConvertVarToString( 3.2 ),@"3.2", @"3.2");
	IDEXPECT( MPWConvertVarToString( @selector(testAnyToString) ),@"testAnyToString", @"@selector");
}

#endif

+(NSArray*)testSelectors
{
    return @[
                @"testOccurencesOf",
//				@"testAnyToString",
                ];
}

@end

@implementation NSObject(StringAdditions)

-(NSString*)stringValue
/*"
    Fall-back implementation returns #{-description}.
"*/
{
    return [self description];
}
-(NSData*)asData
/*"
        Fall-back implementation returns #{-description} as a data.
"*/
{
    return [[self stringValue] asData];
}

@end

@implementation NSData(asData)

-(NSData*)asData
{
    return self;
}

@end
@interface MPWStringExtensionTesting:NSObject
@end
@implementation MPWStringExtensionTesting:NSObject
{
    
}

+(void)testUniquedByNumbering
{
    id pool,res1,res2,res3;

    pool=[NSSet setWithObjects:@"test",@"hi",@"blah",@"test-1",nil];
    res1 = [@"there" uniquedByNumberingInPool:pool];
    res2 = [@"hi" uniquedByNumberingInPool:pool];
    res3 = [@"test" uniquedByNumberingInPool:pool];
    NSAssert2( [res1 isEqual:@"there"], @"expected 'there' got %@ when uniqing 'there' against %@",res1,pool);
    NSAssert2( [res2 isEqual:@"hi-1"], @"expected 'hi-1' got %@ when uniqing 'hi' against %@",res1,pool);
    NSAssert2( [res3 isEqual:@"test-2"], @"expected 'test-2' got %@ when uniqing 'test' against %@",res1,pool);
}

+(void)testUniquedUpdating
{
    id pool,res1,res2,res3;
    id pool1,pool2,pool3;
    pool=[NSMutableSet setWithObjects:@"test",nil];
    pool1=[[pool copy] autorelease];
    res1 = [@"test" uniquedByNumberingInUpdatingPool:pool];
    pool2=[[pool copy] autorelease];
    res2 = [@"test" uniquedByNumberingInUpdatingPool:pool];
    pool3=[[pool copy] autorelease];
    res3 = [@"test" uniquedByNumberingInUpdatingPool:pool];
    NSAssert2( [res1 isEqual:@"test-1"], @"expected 'test-1' got %@ when uniqing 'test' against %@",res1,pool1);
    NSAssert2( [res2 isEqual:@"test-2"], @"expected 'test-2' got %@ when uniqing 'test' against %@",res1,pool2);
    NSAssert2( [res3 isEqual:@"test-3"], @"expected 'test-3' got %@ when uniqing 'test' against %@",res1,pool3);
}

+(void)testCamelCase
{
    IDEXPECT([@"Polymorphic" camelCaseString], @"polymorphic", @"single word");
    IDEXPECT([@"Polymorphic Identifiers" camelCaseString], @"polymorphicIdentifiers", @"single word");
}

+(void)testReinit
{
    NSMutableString *a=[NSMutableString stringWithString:@"Hi there"];
    [a reinit];
    INTEXPECT(a.length, 0, @"empty after reinit");
    IDEXPECT(a, @"", @"empty after reinit")
}

+testSelectors
{
    return @[ @"testUniquedByNumbering",
              @"testUniquedUpdating",
              @"testReinit",
//              @"testCamelCase",
              ];
}

@end


@implementation NSCharacterSet(whiteSpaceAndPunctuation)

+(instancetype)whiteSpaceAndPunctuation
{
    NSMutableCharacterSet *ws=[NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *punct=[NSCharacterSet punctuationCharacterSet];
    [ws formUnionWithCharacterSet:punct];
    return ws;
}

@end
