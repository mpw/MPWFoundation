//
//  MPWPListBuilder.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 1/3/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import "MPWPListBuilder.h"
#import <AccessorMacros.h>
#import <MPWSmallStringTable.h>
#import <MPWWriteStream.h>

@implementation MPWPListBuilder



idAccessor( plist , setPlist )

-init
{
	self=[super init];
	tos = containerStack;
    self.streamingThreshold=-1;
	return self;
}

+builder
{
	return [[[self alloc] init] autorelease];
}	

#define ARRAYTOS	(NSMutableArray*)(tos->container)
#define DICTTOS		(NSMutableDictionary*)(tos->container)

-(void)writeObject:anObject forKey:aKey
{
	[DICTTOS setObject:anObject forKey:aKey];
}


-(void)pushObject:anObject
{	
	if (!plist ) {
		[self setPlist:anObject];
	} else {
		if  ( key ) {
			[self writeObject:anObject forKey:key];
			key=nil;
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

-(void)writeInteger:(long)anInteger
{
    [self pushObject:@(anInteger)];
}

-result
{
	return plist;
}

-(void)clearResult
{
    plist = nil;
}
		 
-(void)pushContainer:anObject
{
	[self pushObject:anObject];
	tos++;
    tos->container=anObject;
//	[anObject release];
}

-(void)beginArray
{
#ifndef __clang_analyzer__
	[self pushContainer:[[NSMutableArray alloc] init]];
#endif
    _arrayDepth++;
}

-(void)endArray
{
    _arrayDepth--;
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
    if ( self.arrayDepth <= self.streamingThreshold) {
        [self.target writeObject:[ARRAYTOS lastObject]];
        [ARRAYTOS removeLastObject];
    }
}

-(NSString*)key
{
    return key;
}

-(void)writeKey:(NSString*)aKey
{
    key=aKey;
}


-(void)dealloc
{
	[plist release];
//	[containerStack release];
    [(id)_target release];
	[super dealloc];
}
	 
- (void)writeObject:(id)anObject {
    [anObject writeOnMPWStream:(MPWWriteStream*)self];
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

+(void)testStreaming
{
    MPWPListBuilder *builder=[self builder];
    NSMutableArray *target=[NSMutableArray array];
    builder.target=target;
    builder.streamingThreshold=1;

    [builder beginArray];
    [builder beginDictionary];
    [builder writeObject:@"Hello World" forKey:@"key1"];
    [builder endDictionary];
    [builder endArray];
    INTEXPECT([builder.result count], 0, @"results were streamed");
    INTEXPECT(target.count, 1, @"results were streamed");
    IDEXPECT([target.lastObject objectForKey:@"key1"], @"Hello World", @"dict was streameed");

}

+(NSArray*)testSelectors
{
	return [NSArray arrayWithObjects:
			@"testBuildString",
			@"testBuildTopLevelArrays",
			@"testBuildTopLevelDicts",
            @"testNestedContainers",
            @"testStreaming",
			nil];
}
		 
@end
