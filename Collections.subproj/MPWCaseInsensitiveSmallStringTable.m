//
//  MPWCaseInsensitiveSmallStringTabe.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/6/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import "MPWCaseInsensitiveSmallStringTable.h"
#import "DebugMacros.h"

@implementation MPWCaseInsensitiveSmallStringTable

-initWithObjects:(id*)values forKeys:(id*)keys count:(NSUInteger)count
{
	int i;
	id lowercaseKeys[ count ];
	for (i=0;i<count;i++) {
		lowercaseKeys[i]=[keys[i] lowercaseString];
	}
	return [super initWithObjects:values forKeys:lowercaseKeys count:count];
}


-objectForCString:(const char*)cstr length:(int)len
{
	int i;
	char lowercasestring[ len+1 ];
	for (i=0;i<len;i++) {
		lowercasestring[i]=tolower(cstr[i]);
	}
	return [super objectForCString:lowercasestring length:len];
}


@end


@implementation MPWCaseInsensitiveSmallStringTable(testing)

+_testKeys
{
	return [NSArray arrayWithObjects:@"Help", @"Marcel", @"me", nil];
}

+_testValues
{
	return [NSArray arrayWithObjects:@"Value for Help", @"Value 2", @"myself and I", nil];
}

+_testCreateTestTable
{
	NSArray *keys=[self _testKeys];
	NSArray *values=[self _testValues];
	MPWSmallStringTable *table=[[[self alloc] initWithKeys:keys values:values ] autorelease];
	return table;
}

+(void)testSimpleCStringLookup
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	NSArray *values=[self _testValues];
	IDEXPECT( [table objectForCString:"Help"] , [values objectAtIndex:0], @"first lookup" );
	IDEXPECT( [table objectForCString:"Marcel"] , [values objectAtIndex:1], @"second lookup" );
	IDEXPECT( [table objectForCString:"me"] , [values objectAtIndex:2], @"thrid lookup" );
}

+(void)testSimpleNSStringLookup
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	NSArray *values=[self _testValues];
	IDEXPECT( [table objectForKey:@"Help"] , [values objectAtIndex:0], @"first lookup" );
	IDEXPECT( [table objectForKey:@"help"] , [values objectAtIndex:0], @"first lookup" );
	IDEXPECT( [table objectForKey:@"marcel"] , [values objectAtIndex:1], @"second lookup" );
	IDEXPECT( [table objectForKey:@"Marcel"] , [values objectAtIndex:1], @"second lookup" );
	IDEXPECT( [table objectForKey:@"me"] , [values objectAtIndex:2], @"thrid lookup" );
}

+(void)testSimpleCStringLengthLookup
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	NSArray *values=[self _testValues];
	IDEXPECT( [table objectForCString:"help" length:4] , [values objectAtIndex:0], @"first lookup" );
	IDEXPECT( [table objectForCString:"Help" length:4] , [values objectAtIndex:0], @"first lookup" );
	IDEXPECT( [table objectForCString:"Marcel" length:6] , [values objectAtIndex:1], @"second lookup" );
	IDEXPECT( [table objectForCString:"marcel" length:6] , [values objectAtIndex:1], @"second lookup" );
	IDEXPECT( [table objectForCString:"me"  length:2] , [values objectAtIndex:2], @"thrid lookup" );
}

+(void)testLookupOfNonExistingKey
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	IDEXPECT( [table objectForKey:@"bozo"], nil, @"non-existing key");
}

+(void)testLookupViaMacro
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	NSArray *values=[self _testValues];
	IDEXPECT( OBJECTFORCONSTANTSTRING(table,"Marcel"), [values objectAtIndex:1], @"lookup via macro");
}

+(void)testKeyAtIndex
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	
	IDEXPECT( [table keyAtIndex:0] , @"help", @"key access");
	IDEXPECT( [table keyAtIndex:1] , @"marcel", @"key access");
	IDEXPECT( [table keyAtIndex:2] , @"me", @"key access");
}




+(void)testFailedLookupGetsDefaultValue
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	char *key="something not in table";
	id defaultResult=@"my default result";
	INTEXPECT(0, [table objectForCString:key] , @"should not have found anything" );
	[table setDefaultValue:defaultResult];
	IDEXPECT(defaultResult, [table objectForCString:key] , @"should have found the default result" );
}


+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testSimpleCStringLookup",
			@"testSimpleNSStringLookup",
			@"testSimpleCStringLengthLookup",
			@"testLookupViaMacro",
			@"testFailedLookupGetsDefaultValue",
			@"testKeyAtIndex",
			nil];
}
@end
