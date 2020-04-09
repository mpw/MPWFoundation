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
#import <MPWFoundation/MPWSmallStringTable.h>

#define USE_BUILDER 1

@implementation MPWMASONParser

objectAccessor( MPWSmallStringTable, commonStrings, setCommonStrings )

-init
{
	self=[super init];
#if USE_BUILDER
    [self setBuilder:[MPWPListBuilder builder]];
#endif
	return self;
}

-(void)setFrequentStrings:(NSArray*)strings
{
	[self setCommonStrings:[[[MPWSmallStringTable alloc] initWithKeys:strings values:strings] autorelease]];
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

-(NSString*)makeRetainedJSONStringStart:(const char*)start length:(long)len
{
	NSString *curstr;
	if ( commonStrings  ) {
//        NSLog(@"will attempt to fetch cstring '%.*s' from common strings",len,start);
//        NSLog(@"common strings: %@",commonStrings);
		NSString *res=OBJECTFORSTRINGLENGTH( commonStrings, start, len );
//        NSLog(@"did fetch: %@",res);
		if ( res ) {
			return [res retain];
		}
	}
//	return MAKEDATA( start , len );
	char buf[ len+1 ];
	char *dest=buf;
	const char *end=start+len;
	while ( start < end ) {
		if ( *start == '\\' ) {
			start++;
			switch (*start) {
				case '"':
				case '\\':
				case '/':
					*dest++=*start;
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
					NSString *charString=[NSString stringWithCharacters:&charvalue length:1];
					[charString getCString:dest maxLength:5 encoding:NSUTF8StringEncoding];
					dest+=strlen(dest);
					start+=4;

				}

					break;
				default:
					break;
			}
			start++;
		} else {
			*dest++=*start++;
		}
	}
	
#ifndef __clang_analyzer__
	curstr=[[NSString alloc] initWithBytes:buf length:dest-buf encoding:NSUTF8StringEncoding];
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
#if USE_BUILDER				
				[_builder beginDictionary];
#else				
				[self pushTag:@"dict"];
#endif				
				inDict=YES;
				inArray=NO;
//                NSLog(@"{ -- start dict");
				curptr++;
				break;
			case '}':
#if USE_BUILDER				
				[_builder endDictionary];
#else				
				[self endDictionary];
#endif				
//				NSLog(@"} -- end dict");
				curptr++;
				break;
			case '[':
//				NSLog(@"[ -- start array");
#if USE_BUILDER				
				[_builder beginArray];
#else				
				[self pushTag:@"array"];
#endif				
				inDict=NO;
				inArray=YES;
				curptr++;
				break;
			case ']':
//				NSLog(@"] -- end array");
#if	USE_BUILDER
				[_builder endArray];
#else				
				[self endArray];
#endif				
				curptr++;
				break;
			case '"':
                parsestring( curptr , endptr, &stringstart, &curptr  );
                curstr = [self makeRetainedJSONStringStart:stringstart length:curptr-stringstart];
//				NSLog(@"found string: '%@'  curptr: %c",curstr,*curptr);
				curptr++;
//				NSLog(@"curptr after end of string skip: %c",*curptr);
				if ( *curptr == ':' ) {
//					NSLog(@"writeKey: %@",curstr);
#if USE_BUILDER					
					[_builder writeKey:curstr];
#else					
					[self pushObject:curstr forKey:@"key" withNamespace:nil];
#endif					
					curptr++;
					
				} else {
#if USE_BUILDER					
					[_builder writeString:curstr];
#else					
					[self pushObject:curstr forKey:@"string" withNamespace:nil];
#endif					
				}
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
					number = isReal ? [self realElement:numstart length:curptr-numstart] :
					[self integerElementAtPtr:numstart length:curptr-numstart];

//				NSLog(@"write number: %@",number);
#if USE_BUILDER					
				[_builder writeString:number];
#else
				[self pushObject:number forKey:@"number" withNamespace:nil];
#endif				
				break;
			}
			case 't':
				if ( (endptr-curptr) >=4  && !strncmp(curptr, "true", 4)) {
					// return true;
					curptr+=4;
//					NSLog(@"true");
#if USE_BUILDER					
					[_builder pushObject:true_value];
#else
					[self pushObject:[true_value retain] forKey:@"true" withNamespace:nil];
#endif
				}
				break;
			case 'f':
				if ( (endptr-curptr) >=5  && !strncmp(curptr, "false", 5)) {
					// return false;
					curptr+=5;
//					NSLog(@"false");
#if USE_BUILDER					
					[_builder pushObject:false_value];
#else
					[self pushObject:[false_value retain] forKey:@"false" withNamespace:nil];
#endif

				}
				break;
			case 'n':
				if ( (endptr-curptr) >=4  && !strncmp(curptr, "null", 4)) {
					// return null;
//					NSLog(@"null");
#if USE_BUILDER					
					[_builder pushObject:[NSNull null]];
#else
					[self pushObject:[[NSNull null] retain] forKey:@"null" withNamespace:nil];
#endif
					curptr+=4;
				}
				break;
			case ' ':
			case '\n':
//				NSLog(@"whitespace");
				while (curptr < endptr && isspace(*curptr)) {
					curptr++;
				}
//				NSLog(@"curptr after whitespace: %c",*curptr);
				break;

			default:
				[NSException raise:@"invalidcharacter" format:@"JSON invalid character %x/'%c' at %td",*curptr,*curptr,curptr-(char*)[data bytes]];
				break;
		}
	}
#if USE_BUILDER
    return [_builder result];
#else
	return [self parseResult];
#endif

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
        @autoreleasepool {
            parser=[[MPWMASONParser alloc] init];
        }

        NSData *json=[self frameworkResource:@"array" category:@"json"];
        NSString *string1=@"first";
        NSString *string2=@"second";
//        NSLog(@"will parse");
        NSArray *array=[parser parsedData:json];
//        NSLog(@"did parse");
        EXPECTFALSE( [array objectAtIndex:0] == string1 ,@"did not expect the same string for string1");
        EXPECTFALSE( [array objectAtIndex:1] == string2 ,@"did not expect the same string for string2");
        @autoreleasepool {
            [parser setFrequentStrings:[NSArray arrayWithObjects:string1,string2,nil]];
        }
//        NSLog(@"before parse with frequent strings");
        @autoreleasepool {
            array=[[parser parsedData:json] retain];
        }
        
//        NSLog(@"after parse with frequent strings");
//        NSLog(@"parser retainCount: %d",[parser retainCount]);
        [parser release];
//        NSLog(@"result array: %@",array);
#if !USE_BUILDER
        EXPECTTRUE( [array objectAtIndex:0] == string1 ,@"expected the same string for string1");
        EXPECTTRUE( [array objectAtIndex:1] == string2 ,@"expected the same string for string2");
#endif
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



+testSelectors
{
	return [NSArray arrayWithObjects:
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
			nil];
}

+focusTests
{
    return [self testSelectors];
}

@end

#endif
