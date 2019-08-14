//
//  MPWPListBuilder.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWPListBuilder.h"
#import "AccessorMacros.h"

@implementation MPWPListBuilder


idAccessor( key , setKey )
idAccessor( plist , setPlist )
//objectAccessor( NSMutableArray, containerStack, setContainerStack )

-init
{
	self=[super init];
//	[self setContainerStack:[NSMutableArray array]];
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
	[DICTTOS setObject:anObject forKey:key];
}


-(void)pushObject:anObject
{	
	if (!plist ) {
		[self setPlist:anObject];
	} else {
		if  (key ) {
			[self writeObject:anObject forKey:key];
			[self setKey:nil];
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
	[anObject release];
}

-(void)beginArray
{
	[self pushContainer:[[NSMutableArray alloc] init]];

}

-(void)endArray
{
	tos--;
}

-(void)beginDictionary
{
	[self pushContainer:[[NSMutableDictionary alloc] init]];
}

-(void)endDictionary
{
	tos--;
}

-(void)writeKey:aKey
{
	[self setKey:aKey];
}


-(void)dealloc
{
	[plist release];
//	[containerStack release];
	[key release];
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
	[builder writeKey:@"key"];
	[builder writeString:@"Hello World"];
	[builder endDictionary];
	IDEXPECT([[builder result] objectForKey:@"key"],@"Hello World", @"simple string in dict");
}

+(void)testNestedContainers
{
	MPWPListBuilder *builder=[self builder];
	[builder beginDictionary];
	[builder writeKey:@"key1"];
	[builder beginArray];
	[builder beginDictionary];
	[builder writeKey:@"key2"];
	[builder writeString:@"hello world"];
	[builder endDictionary];
	[builder writeString:@"array string"];
	[builder endArray];
	[builder writeKey:@"key3"];
	[builder beginDictionary];
	[builder writeKey:@"key34"];
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
