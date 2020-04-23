//
//  MPWPListBuilder.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWPListBuilder.h"
#import "AccessorMacros.h"
#import "MPWSmallStringTable.h"

@implementation MPWPListBuilder



idAccessor( plist , setPlist )

-init
{
	self=[super init];
	tos = containerStack;
	return self;
}

+builder
{
	return [[[self alloc] init] autorelease];
}	

#define ARRAYTOS	(NSMutableArray*)(*tos)
#define DICTTOS		(NSMutableDictionary*)(*tos)

-(void)writeObject:anObject forKey:aKey
{
	[DICTTOS setObject:anObject forKey:[self key]];
}


-(void)pushObject:anObject
{	
	if (!plist ) {
		[self setPlist:anObject];
	} else {
		if  (keyStr ) {
			[self writeObject:anObject forKey:[self key]];
			keyStr=NULL;
		} else {
			[ARRAYTOS addObject:anObject];
		}
	}
}	



-(void)writeString:(NSString*)aString
{
	[self pushObject:aString];
}


-(void)writeNumber:(NSString*)aString
{
	[self pushObject:aString];
}

-result
{
	return plist;
}
		 
-(void)pushContainer:anObject
{
	[self pushObject:anObject];
	tos++;
	*tos=anObject;
//	[anObject release];
}

-(void)beginArray
{
#ifndef __clang_analyzer__
	[self pushContainer:[[NSMutableArray alloc] init]];
#endif
}

-(void)endArray
{
	tos--;
}

-(void)beginDictionary
{
#ifndef __clang_analyzer__
	[self pushContainer:[[NSMutableDictionary alloc] init]];
#endif
}

-(void)endDictionary
{
	tos--;
}

-(NSString*)key
{
    NSString *key=nil;
    if ( keyStr) {
        if ( _commonStrings ) {
            key=OBJECTFORSTRINGLENGTH(_commonStrings, keyStr, keyLen);
        }
        if ( !key ) {
            key=[[[NSString alloc] initWithBytes:keyStr length:keyLen encoding:NSUTF8StringEncoding] autorelease];
        }
    }
    return key;
}

-(void)writeKeyString:(const char*)aKey length:(long)len
{
    keyStr=aKey;
    keyLen=len;
}


-(void)dealloc
{
	[plist release];
//	[containerStack release];
	[super dealloc];
}
	 
@end

#import "DebugMacros.h"

@implementation MPWPListBuilder(testing)

+(void)testBuildString
{
	MPWPListBuilder *builder=[self builder];
	[builder writeString:@"Hello World"];
	IDEXPECT([builder result],@"Hello World", @"simple string");
}

+(void)testBuildTopLevelArrays
{
	MPWPListBuilder *builder=[self builder];
	[builder beginArray];
	[builder writeString:@"Hello World"];
	[builder endArray];
	IDEXPECT([builder result],[NSArray arrayWithObject:@"Hello World"], @"simple string");
}

+(void)testBuildTopLevelDicts
{
	MPWPListBuilder *builder=[self builder];
	[builder beginDictionary];
    [builder writeKeyString:"key" length:3];
	[builder writeString:@"Hello World"];
	[builder endDictionary];
	IDEXPECT([[builder result] objectForKey:@"key"],@"Hello World", @"simple string in dict");
}

+(void)testNestedContainers
{
	MPWPListBuilder *builder=[self builder];
	[builder beginDictionary];
    [builder writeKeyString:"key1" length:4];
	[builder beginArray];
	[builder beginDictionary];
    [builder writeKeyString:"key2" length:4];
	[builder writeString:@"hello world"];
	[builder endDictionary];
	[builder writeString:@"array string"];
	[builder endArray];
    [builder writeKeyString:"key3" length:4];
	[builder beginDictionary];
    [builder writeKeyString:"key34" length:5];
	[builder writeString:@"nested dict"];
	[builder endDictionary];
	[builder endDictionary];
	NSDictionary *dict=[builder result];
	INTEXPECT( [dict count], 2, @"top level dict size");
	NSArray *array=[dict objectForKey:@"key1"];
	INTEXPECT( [array count], 2, @"1st nested array size");
	IDEXPECT( [array objectAtIndex:1], @"array string", @"1st nested array 2nd element");
	IDEXPECT( [[array objectAtIndex:0] objectForKey:@"key2"], @"hello world", @"1st nested dict");
}

+(NSArray*)testSelectors
{
	return [NSArray arrayWithObjects:
			@"testBuildString",
			@"testBuildTopLevelArrays",
			@"testBuildTopLevelDicts",
			@"testNestedContainers",
			nil];
}
		 
@end
