//
//  MPWMASONParser.m
//  ObjectiveXML
//
//  Created by Marcel Weiher on 12/29/10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWMASONParser.h"
#import "MPWMAXParser_private.h"
#import <MPWFoundation/MPWPListBuilder.h>
#import <MPWFoundation/MPWObjectBuilder.h>
#import <MPWFoundation/MPWSmallStringTable.h>


@implementation MPWMASONParser

objectAccessor( MPWSmallStringTable, commonStrings, setCommonStrings )

-initWithBuilder:aBuilder
{
    self=[super init];
    [self setBuilder:aBuilder];
    self.stringCache = [MPWObjectCache cacheWithCapacity:20 class:[NSMutableString class]];
    id dummy=[NSMutableString alloc];
    [self.stringCache setInitIMP:(IMP0)[dummy methodForSelector:@selector(init)]];
    self.stringCache.unsafeFastAlloc = YES;
    return self;
}

-init
{
    return [self initWithBuilder:[MPWPListBuilder builder]];
}

-initWithClass:(Class)classToDecode
{
    self = [self initWithBuilder:[[[MPWObjectBuilder alloc] initWithClass:classToDecode] autorelease]];
    [self setFrequentStrings:(NSArray*)[[[classToDecode ivarNames] collect] substringFromIndex:1]];
    return self;
}

-(void)setFrequentStrings:(NSArray*)strings
{
	[self setCommonStrings:[[[MPWSmallStringTable alloc] initWithKeys:strings values:strings] autorelease]];
    [(id)[self builder] setCommonStrings:[self commonStrings]];
}

-(void)pushResult:result withTag:(NSString*)tag
{
	[CURRENTELEMENT.children removeAllObjects];
	[CURRENTELEMENT.attributes release]; //=retainMPWObject( attrs ) ;
	CURRENTELEMENT.attributes=nil;
	[self popTag];
	[self pushObject:result forKey:tag withNamespace:nil];
}

-(void)endDictionary
{
    NSDictionary *dict=[self dictElement:CURRENTELEMENT.children attributes:nil parser:self ];
	[self pushResult:dict withTag:@"dict"];
    [dict release];
}

-(void)endArray
{
    NSArray *array=[self arrayElement:CURRENTELEMENT.children attributes:nil parser:self ];
	[self pushResult:array withTag:@"array"];
    [array release];
}

-(void)pushTag:(id)aTag
{
	[super pushTag:aTag];
	if ( ! CURRENTELEMENT.children ) {
		CURRENTELEMENT.children=[[MPWXMLAttributes alloc] init];
	} else {
		[CURRENTELEMENT.children removeAllObjects];
	}
	
}

static long nsstrings=0;
static long subdatas=0;
static long common=0;


-(NSString*)makeJSONStringStart:(const char*)start length:(long)len
{
    if ( len==0) {
        return @"";
    }
    const char* realstart=start;
	NSString *curstr;
	if ( commonStrings  ) {
		NSString *res=OBJECTFORSTRINGLENGTH( commonStrings, start, len );
		if ( res ) {
            common++;
			return res;
		}
	}


    
	unichar buf[ len*2 ];
	unichar *dest=buf;
	const char *end=start+len;
    BOOL hasEscape=NO;
    BOOL hasUnicode=NO;
    while ( start < end ) {
        unsigned char ch=*start;
        if ( ch == '\\' ) {
            start++;
            hasEscape=YES;
            ch=*start;
			switch (ch) {
				case '"':
				case '\\':
				case '/':
					*dest++=ch;
					break;
				case 'b':
					*dest++='\b';
					break;
				case 'f':
					*dest++='\f';
					break;
				case 'n':
					*dest++='\n';
					break;
				case 'r':
					*dest++='\r';
					break;
				case 't':
					*dest++='\t';
					break;
				case 'u':
				{
                    char hexstring[5];
                    memcpy(hexstring, start+1, 4);
                    hexstring[4]=0;
					unsigned int value=0;
                    unichar charvalue=0;
                    sscanf( hexstring, "%x",&value); 
					charvalue=value;
                    *dest++=charvalue;
					start+=4;

				}

					break;
				default:
					break;
			}
			start++;
        } else if ( ch & 128 ) {         // UTF8
            hasUnicode=YES;
            unsigned char c=*start++;
            unsigned char c1,c2,c3;
            unichar r=0;
            if ((c & 0xE0) == 0xC0) {
                c1 = *start++;
                if (c1 >= 0) {
                    r = ((c & 0x1F) << 6) | c1;
                }

                /*
                 Two continuations (2048 to 55295 and 57344 to 65535)
                 */
            } else if ((c & 0xF0) == 0xE0) {
                c1 = *start++;
                c2 = *start++;
                if ((c1 | c2) >= 0) {
                    r = ((c & 0x0F) << 12) | (c1 << 6) | c2;
                }

                /*
                 Three continuations (65536 to 1114111)
                 */
            } else if ((c & 0xF8) == 0xF0) {
                c1 = *start++;
                c2 = *start++;
                c3 = *start++;
                if ((c1 | c2 | c3) >= 0) {
                    r = ((c & 0x07) << 18) | (c1 << 12) | (c2 << 6) | c3;
                }
            }
            *dest++=r;

        } else {
			*dest++=*start++;
		}
	}
    *dest=0;
#ifndef __clang_analyzer__
    if (hasEscape || hasUnicode) {
#if 0
        curstr=[self.stringCache getObject];
        [curstr reinit];
        [(NSMutableString*)curstr appendFormat:@"%*S",(int)(dest-buf),(const unichar*)buf];
#else
        curstr=[[[NSString alloc] initWithCharacters:buf length:dest-buf] autorelease];
#endif
        nsstrings++;
    } else {
        curstr=MAKEDATA( realstart , len );
        subdatas++;
    }
    return curstr;
#endif
}


static inline void parsestring( const char *curptr , const char *endptr, const char **stringstart, const char **stringend )
{
    curptr++;
    //                NSLog(@"curptr at start of str: '%c'",*curptr);
    *stringstart=curptr;
    while ( curptr < endptr && *curptr != '"' ) {
        //                    NSLog(@"curptr in str: '%c'",*curptr);
        if ( *curptr=='\\'  ) {
            curptr++;
        }
        curptr++;
    }
    *stringend=curptr;
}

-(long)longElementAtPtr:(const char*)start length:(long)len
{
    long val=0;
    int sign=1;
    const char *end=start+len;
    if ( start[0] =='-' ) {
        sign=-1;
        start++;
    } else if ( start[0]=='+' ) {
        start++;
    }
    while ( start < end && isdigit(*start)) {
        val=val*10+ (*start)-'0';
        start++;
    }
    val*=sign;
    return val;
}


-parsedData:(NSData*)jsonData
{
	[self setData:jsonData];
	const char *curptr=[jsonData bytes];
	const char *endptr=curptr+[jsonData length];
	const char *stringstart=NULL;
	NSString *curstr=nil;
	while (curptr < endptr ) {
		switch (*curptr) {
			case '{':
				[_builder beginDictionary];
				inDict=YES;
				inArray=NO;
//                NSLog(@"{ -- start dict");
				curptr++;
				break;
			case '}':
				[_builder endDictionary];
//				NSLog(@"} -- end dict");
				curptr++;
				break;
			case '[':
//				NSLog(@"[ -- start array");
				[_builder beginArray];
				inDict=NO;
				inArray=YES;
				curptr++;
				break;
			case ']':
//				NSLog(@"] -- end array");
				[_builder endArray];
				curptr++;
				break;
			case '"':
                parsestring( curptr , endptr, &stringstart, &curptr  );
                int spaces=0;
                while (curptr[spaces+1] ==' ') {
                    spaces++;
                }
				if ( curptr[spaces+1] == ':' ) {
                    [_builder writeKeyString:stringstart length:curptr-stringstart];
					curptr++;
					
				} else {
                    curstr = [self makeJSONStringStart:stringstart length:curptr-stringstart];
					[_builder writeString:curstr];
				}
                curptr+=spaces+1;
				break;
			case ',':
				curptr++;
				break;
			case '-':
			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
			{
				BOOL isReal=NO;
				const char *numstart=curptr;
				id number=nil;
				if ( *curptr == '-' ) {
					curptr++;
				}
				while ( curptr < endptr && isdigit(*curptr) ) {
					curptr++;
				}
				if ( *curptr == '.' ) {
					curptr++;
					while ( curptr < endptr && isdigit(*curptr) ) {
						curptr++;
					}
					isReal=YES;
				}
				if ( curptr < endptr && (*curptr=='e' | *curptr=='E') ) {
					curptr++;
					while ( curptr < endptr && isdigit(*curptr) ) {
						curptr++;
					}
					isReal=YES;
				}
                if ( isReal) {
                    number = [self realElement:numstart length:curptr-numstart];

                    [_builder writeString:number];
                } else {
                    long n=[self longElementAtPtr:numstart length:curptr-numstart];
                    [_builder writeInteger:n];
                }

				break;
			}
			case 't':
				if ( (endptr-curptr) >=4  && !strncmp(curptr, "true", 4)) {
					curptr+=4;
					[_builder pushObject:true_value];
				}
				break;
			case 'f':
				if ( (endptr-curptr) >=5  && !strncmp(curptr, "false", 5)) {
					// return false;
					curptr+=5;
					[_builder pushObject:false_value];

				}
				break;
			case 'n':
				if ( (endptr-curptr) >=4  && !strncmp(curptr, "null", 4)) {
					[_builder pushObject:[NSNull null]];
					curptr+=4;
				}
				break;
			case ' ':
			case '\n':
				while (curptr < endptr && isspace(*curptr)) {
					curptr++;
				}
				break;

			default:
				[NSException raise:@"invalidcharacter" format:@"JSON invalid character %x/'%c' at %td",*curptr,*curptr,curptr-(char*)[data bytes]];
				break;
		}
	}
    NSLog(@"nsstrings: %ld subdatas: %ld common: %ld",nsstrings,subdatas,common);
    return [_builder result];

}

-(void)dealloc
{
	[(id)_builder release];
	[commonStrings release];
	[super dealloc];
}

@end

#if !TARGET_OS_IPHONE
#import "DebugMacros.h"
#import "NSObjectAdditions.h"

@implementation MPWMASONParser(testing)

+(void)testParseGlossaryToDict
{
	MPWMASONParser *parser=[MPWMASONParser parser];
	NSData *glossaryJSON=[self frameworkResource:@"glossary" category:@"json"];
	EXPECTNOTNIL( glossaryJSON, @"got json source");
	NSDictionary *resultDict=[parser parsedData:glossaryJSON];
	EXPECTNOTNIL( resultDict, @"should have result");
	INTEXPECT( [resultDict count], 1 , @"one top level item");
	NSDictionary *glossary=[resultDict objectForKey:@"glossary"];
	EXPECTNOTNIL( glossary,  @"result");
	IDEXPECT( [glossary objectForKey:@"title"], @"example glossary", @"title");
}

+(id)_parseJSONResource:(NSString*)jsonResource
{
	MPWMASONParser *parser=[MPWMASONParser parser];
	NSData *json=[self frameworkResource:jsonResource category:@"json"];
	return [parser parsedData:json];
}

+(void)testParseJSONString
{
	IDEXPECT( [self _parseJSONResource:@"string"],@"A JSON String", @"json string");
}


+(void)testParseSimpleJSONDict
{
	NSDictionary *resultDict=[self _parseJSONResource:@"dict"];
	INTEXPECT( [resultDict count], 1 , @"one top level item");
	IDEXPECT( [resultDict objectForKey:@"key"], @"value" , @"result");
}

+(void)testParseSimpleJSONArray
{
	NSArray *resultArray=[self _parseJSONResource:@"array"];
	INTEXPECT( [resultArray count], 2 , @"two top level items");
	IDEXPECT( [resultArray objectAtIndex:0], @"first" , @"first item");
	IDEXPECT( [resultArray objectAtIndex:1], @"second" , @"first item");
}

+(void)testParseLiterals
{
	NSArray *literalResults=[self _parseJSONResource:@"literals"];
	INTEXPECT( [literalResults count],3,@"3 items in literal array");
	IDEXPECT( [literalResults objectAtIndex:0], [NSNumber numberWithBool:YES], @"true");
	IDEXPECT( [literalResults objectAtIndex:1], [NSNumber numberWithBool:NO], @"true");
	IDEXPECT( [literalResults objectAtIndex:2], [NSNull null], @"nil");
}

+(void)testParseNumbers
{
	NSArray *numberResults=[self _parseJSONResource:@"numbers"];
	INTEXPECT( [numberResults count], 4 , @"numbers in array");
	INTEXPECT( [[numberResults objectAtIndex:0] intValue], 1 , @"first number");
	INTEXPECT( [[numberResults objectAtIndex:1] intValue], 2, @"second number");
	INTEXPECT( [[numberResults objectAtIndex:2] intValue], 42, @"third number");
	INTEXPECT( (int)(10000000*[[numberResults objectAtIndex:3] doubleValue]), 483506, @"4th number");
}

+(void)testDictAfterNumber
{
	id nestedDictsResults=[self _parseJSONResource:@"dictAfterNumber"];
	EXPECTNOTNIL( nestedDictsResults, @"nested dicts");
}


+(void)testEmptyElements
{
	NSArray *emptyElementResults=[self _parseJSONResource:@"emptyelements"];
	EXPECTNOTNIL( emptyElementResults, @"nested dicts");
	INTEXPECT( (int)[emptyElementResults count], 3, @"num elements");
	EXPECTTRUE( [[emptyElementResults objectAtIndex:0] isKindOfClass:[NSDictionary class]], @"1st is a dictionary" );
	EXPECTTRUE( [[emptyElementResults objectAtIndex:1] isKindOfClass:[NSArray class]], @"2nd is an array" );
	EXPECTTRUE( [[emptyElementResults objectAtIndex:2] isKindOfClass:[NSString class]], @"3rd is a string" );
	INTEXPECT( (int)[[emptyElementResults objectAtIndex:0] count], 0 , @"dict empty");
	INTEXPECT( (int)[[emptyElementResults objectAtIndex:1] count], 0 , @"array empty");
	INTEXPECT( (int)[[emptyElementResults objectAtIndex:2] length], 0 , @"string empty");
}

+(void)testStringEscapes
{
	NSArray *escapedStrings=[self _parseJSONResource:@"stringescapes"];
	INTEXPECT( (int)[escapedStrings count], 8, @"number of strings");
	IDEXPECT( [escapedStrings objectAtIndex:0], @"\"", @"quote");
	IDEXPECT( [escapedStrings objectAtIndex:1], @"\\", @"backslash");
	IDEXPECT( [escapedStrings objectAtIndex:2], @"/", @"slash");
	IDEXPECT( [escapedStrings objectAtIndex:3], @"\b", @"backspace \b");
	IDEXPECT( [escapedStrings objectAtIndex:4], @"\f", @"");
	IDEXPECT( [escapedStrings objectAtIndex:5], @"\n", @"");
	IDEXPECT( [escapedStrings objectAtIndex:6], @"\r", @"");
	IDEXPECT( [escapedStrings objectAtIndex:7], @"\t", @"");
}


+(void)testCommonStrings
{
    @autoreleasepool {
        MPWMASONParser *parser=nil;
        parser=[[MPWMASONParser alloc] init];

        NSData *json=[self frameworkResource:@"array" category:@"json"];
        NSString *string1=@"first";
        NSString *string2=@"second";
//        NSLog(@"will parse");
        NSArray *array=[parser parsedData:json];
//        NSLog(@"did parse");
        EXPECTFALSE( array[0] == string1 ,@"did not expect the same string for string1");
        EXPECTFALSE( array[1]   == string2 ,@"did not expect the same string for string2");
        IDEXPECT( array[0] , string1 ,@"string1");
        IDEXPECT( array[1]  , string2 ,@" string2");
        [parser release];
        parser=[[MPWMASONParser alloc] init];
        [parser setFrequentStrings:@[string1,string2]];
        array=[parser parsedData:json];
        [parser release];
        IDEXPECT( array[0] , string1 ,@"string1");
        IDEXPECT( array[1], string2 ,@" string2");
        EXPECTTRUE( array[0]  == string1 ,@"expected the same string for string1");
        EXPECTTRUE( array[1]  == string2 ,@"expected the same string for string2");
        [array release];
    }
//    NSLog(@"after test pool");
}

+(void)testUnicodeEscapes
{
	MPWMASONParser *parser=[MPWMASONParser parser];
	NSData *json=[self frameworkResource:@"unicodeescapes" category:@"json"];
	NSArray *array=[parser parsedData:json];
	NSString *first = [array objectAtIndex:0];
	INTEXPECT([first length],1,@"length of parsed unicode escaped string");
	INTEXPECT([first characterAtIndex:0], 0x1234, @"expected value");
	IDEXPECT([array objectAtIndex:1], @"\n", @"second is newline");
}

+(void)testSpaceBeforeColon
{
    MPWMASONParser *parser=[MPWMASONParser parser];
    NSData *json=[self frameworkResource:@"filmliste" category:@"json"];
    NSArray *array=[parser parsedData:json];
    INTEXPECT(array.count,2,@"elements");

}

+testSelectors
{
	return @[
			@"testParseJSONString",
			@"testParseSimpleJSONDict",
			@"testParseSimpleJSONArray",
			@"testParseLiterals",
			@"testParseNumbers",
			@"testParseGlossaryToDict",
			@"testDictAfterNumber",
			@"testEmptyElements",
			@"testStringEscapes",
			@"testUnicodeEscapes",
			@"testCommonStrings",
            @"testSpaceBeforeColon",
			];
}

+focusTests
{
    return [self testSelectors];
}

@end

#endif
