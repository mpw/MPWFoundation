//
//  MPWSmallStringTable.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 29/3/07.
//  Copyright 2007-2011 by Marcel Weiher. All rights reserved.
//

#import "MPWSmallStringTable.h"
#import "DebugMacros.h"
#if FULL_MPWFOUNDATION && !WINDOWS && !LINUX
#import "MPWRusage.h"
#endif

@implementation MPWSmallStringTable

idAccessor( defaultValue, setDefaultValue )

#if GATHER_STATISTICS
static int numKeys=0;
static int keyBytes=0;
static int maxLen=0;
static int sizes[256];
static id allkeys=nil;
#endif

IMP __stringTableLookupFun=NULL;

+(void)inititialize
{
	[MPWObject initialize];
}

+(void)printStats
{
#if GATHER_STATISTICS
	int i;
	int cumulative=0;
	NSLog(@"keys: %d length: %d avg. size: %g max size=%d",numKeys,keyBytes,keyBytes/(double)numKeys);
	for ( i=0;i<maxLen;i++ ) {
		cumulative+=sizes[i];
		NSLog(@"%d -> %d  %d%% of total, cumulative %d%%",i,sizes[i],(sizes[i]*100)/numKeys,(cumulative*100)/numKeys);
	}
	NSLog(@"%d distinct keys (%d%%)",[allkeys count],(100*[allkeys count])/numKeys);
	NSLog(@"allKeys: %@",[[allkeys allObjects] sortedArrayUsingSelector:@selector(compare:)]); 
#endif	
}

-initWithObjects:(id*)values forKeys:(id*)keys count:(NSUInteger)count
{
//	NSLog(@" initWithObjects:forKeys:count: %d --- ",count);
//	NSLog(@"will super init");
#ifndef WINDOWS
	self=[super init];
#endif
	if ( self ) {
		int i;
		int lengths[ count +1 ];
		int totalStringLen=0;
		 char *curptr;
//		NSLog(@"super init");
		for (i=0;i<count;i++) {
			lengths[i]=[keys[i] length];
			totalStringLen+=lengths[i]+1;
		}
		tableLength=count;
		table=malloc( totalStringLen +1 );
		tableValues=ALLOC_POINTERS( (count+1)* sizeof(id) );
//		NSLog(@"tableValues=%p",tableValues);
//		memcpy( tableValues, values, count * sizeof(id));
		curptr=table;
//		NSLog(@"table=%p curptr=%p",table,curptr);
		for (i=0;i<tableLength;i++) {
			int encoding=NSUTF8StringEncoding;
#if WINDOWS
			encoding=NSISOLatin1StringEncoding;
#endif
			NSString* key=keys[i];
			int len=lengths[i];
			id value=values[i];
			*curptr++=len;
			tableValues[i]=[value retain];
			[key getCString:curptr maxLength:len+1 encoding:encoding];
			curptr+=len;
//			table[i].offset=0;
			
			
#if GATHER_STATISTICS
			numKeys++;
			sizes[len]++;
			keyBytes+=table[i].length;
			if ( len > maxLen ) {
				maxLen=len;
			}
			if ( !allkeys ) {
				allkeys=[[NSMutableSet set] retain];
			}
			[allkeys addObject:key];
#endif			
		}
		if ( !__stringTableLookupFun ) {
			__stringTableLookupFun=[self methodForSelector:@selector(objectForCString:length:)];
		}
		[self setDefaultValue:nil];
	}
	return self;

}

-initWithKeys:(NSArray*)keys values:(NSArray*)values
{
//	NSLog(@"initWithKeys: %d values: %d",[keys count],[values count]);
	id keyArray[ [keys count] +1 ];
	id valueArray[ [values count] + 1];
	[keys getObjects:keyArray];
	[values getObjects:valueArray];
//	NSLog(@"will initWithObjects:forKeys:count");
	return [self initWithObjects:valueArray forKeys:keyArray count:[keys count]];
}

-(NSUInteger)count
{
	return tableLength;
}

-objectForKey:(NSString*)key
{
	int encoding=NSUTF8StringEncoding;
#if WINDOWS
	encoding=NSISOLatin1StringEncoding;
#endif
	int len=[key length];
	char buffer[len+20];
	[key getCString:buffer maxLength:len+10 encoding:encoding];
	buffer[len]=0;
	return [self objectForCString:buffer length:len];
}

-objectAtIndex:(NSUInteger)anIndex
{
	if ( anIndex < tableLength ) {
		return tableValues[anIndex];
	} else {
		return nil;
	}
}

- (void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:(id)anObject
{
	if (  anIndex < tableLength ) {
		[anObject retain];
		[tableValues[anIndex] release];
		tableValues[anIndex]=anObject;
	} else {
		[NSException raise:@"indexOutOfBounds" format:@"index %d out bounds",anIndex];
	}
}

-keyAtIndex:(NSUInteger)anIndex
{
	if ( anIndex < tableLength ) {
		int i;
		char *curptr=table;
		for (i=0;i<anIndex;i++) {
			curptr+=*curptr + 1;
		}
		return [[[NSString alloc] initWithBytes:curptr+1 length:*curptr encoding:NSUTF8StringEncoding] autorelease];
	} else {
		return nil;
	}
}

static int offsetOfCStringWithLengthInTableOfLength( char  *table, NSUInteger tableLength, char *cstr, NSUInteger len)
{
	int i;
	const char *curptr=table;
	for (i=0; i<tableLength;i++ ) {
		int entryLen=*curptr;
		if ( len==entryLen ) {
			int offset=0;
//			int offset=table[i].offset;
//			char *tablestring=table[i].string;
			const char *tablestring=curptr+1;

			if ( (cstr[offset])==(tablestring[offset]) ) {
				if (!strncmp( cstr, tablestring , len ) ) {
					return i;
				}
			}
#if 0
				int j;
				for (j=0;j<len;j+=2) {
					if ( cstr[j] != tablestring[j] ) {
						goto notequal;
					}
					if ( cstr[j+1] != tablestring[j+1] ) {
						goto notequal;
					}
				}
				return table[i].vialue;
			}
			notequal:
				continue;
#endif				
		}
		curptr+=entryLen+1;
	}
	return -1;
}

-(int)offsetForCString:(char*)cstr length:(int)len
{
	int offset = offsetOfCStringWithLengthInTableOfLength( table , tableLength, cstr, len );
	return offset;
}
-(int)offsetForCString:(char*)cstr
{
	return [self offsetForCString:cstr length:strlen(cstr)];
}

-(void)setObject:anObject forKey:aKey
{
	const char *str=[aKey UTF8String];
	int offset=[self offsetForCString:str];
	if ( offset >= 0 ) {
		[self replaceObjectAtIndex:offset  withObject:anObject];
	} else {
		[NSException raise:@"setObjectForKey-nokey" format:@"key %@ not already present in dict",aKey];
	}
}


-objectForCString:(char*)cstr length:(int)len
{
	int offset = offsetOfCStringWithLengthInTableOfLength( table , tableLength, cstr, len );
	if ( offset >= 0 ) {
		return tableValues[offset];
	} else {
		return defaultValue;
	}
}
-objectForCString:(char*)cstr
{
	return [self objectForCString:cstr length:strlen(cstr)];
}

-description
{
	int i;

	id result=[NSMutableString stringWithString:@"{ "];
	for (i=0;i<tableLength;i++) {
		[result appendFormat:@"%@=%@;\n",[self keyAtIndex:i],[self objectAtIndex:i]];
	}
	[result appendFormat:@" }\n"];
	return result;
}

- retain
{
    return retainMPWObject( (MPWObject*)self );
}

- (NSUInteger)retainCount
{
    return __retainCount+1;
}

- (oneway void)release
{
    releaseMPWObject((MPWObject*)self);
}



-(void)dealloc
{
	if ( tableValues ) {
		int i;
		for (i=0;i<tableLength;i++) {
			[tableValues[i] release];
		}
		free(tableValues);
	}
	if ( table ) {
		free(table);
	}
	[defaultValue release];
	[super dealloc];
}

@end


@implementation MPWSmallStringTable(testing)

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
	IDEXPECT( [table objectForKey:@"Marcel"] , [values objectAtIndex:1], @"second lookup" );
	IDEXPECT( [table objectForKey:@"me"] , [values objectAtIndex:2], @"thrid lookup" );
}

+(void)testSimpleCStringLengthLookup
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	NSArray *values=[self _testValues];
	IDEXPECT( [table objectForCString:"Help" length:4] , [values objectAtIndex:0], @"first lookup" );
	IDEXPECT( [table objectForCString:"Marcel" length:6] , [values objectAtIndex:1], @"second lookup" );
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
	
	IDEXPECT( [table keyAtIndex:0] , @"Help", @"key access");
	IDEXPECT( [table keyAtIndex:1] , @"Marcel", @"key access");
	IDEXPECT( [table keyAtIndex:2] , @"me", @"key access");
}

#define LOOKUP_COUNT 1000000
#if FULL_MPWFOUNDATION && !WINDOWS && !LINUX

+(void)testLookupFasterThanNSDictionary
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	NSDictionary *dict=[NSDictionary dictionaryWithObjects:[self _testValues] forKeys:[self _testKeys]];
	MPWRusage* slowStart=[MPWRusage current];
	int i;
	for (i=0;i<LOOKUP_COUNT;i++) {
		[dict objectForKey:@"Marcel"];
	}
	MPWRusage* slowTime=[MPWRusage timeRelativeTo:slowStart];
	MPWRusage* fastStart=[MPWRusage current];
	for (i=0;i<LOOKUP_COUNT;i++) {
		OBJECTFORCONSTANTSTRING(table,"Marcel");
	}
	MPWRusage* fastTime=[MPWRusage timeRelativeTo:fastStart];
	double ratio = (double)[slowTime userMicroseconds] / (double)[fastTime userMicroseconds];
	NSLog(@"dict time: %d (%g ns/iter) stringtable time: %d (%g ns/iter)",[slowTime userMicroseconds],(1000.0*[slowTime userMicroseconds])/LOOKUP_COUNT,[fastTime userMicroseconds],(1000.0*[fastTime userMicroseconds])/LOOKUP_COUNT);
	NSLog(@"dict vs. string table lookup time ratio: %g",ratio);
	NSAssert2( ratio > 2.5 ,@"ratio of small string table to NSDictionary %g < %g",
				ratio,2.5);   
}

+(void)testLookupFasterThanMPWUniqueString
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	MPWRusage* slowStart=[MPWRusage current];
	int i;
	for (i=0;i<LOOKUP_COUNT;i++) {
		MPWUniqueStringWithCString("Marcel", 6);
	}
	MPWRusage* slowTime=[MPWRusage timeRelativeTo:slowStart];
	MPWRusage* fastStart=[MPWRusage current];
	for (i=0;i<LOOKUP_COUNT;i++) {
		OBJECTFORCONSTANTSTRING(table,"Marcel");
	}
	MPWRusage* fastTime=[MPWRusage timeRelativeTo:fastStart];
	double ratio = (double)[slowTime userMicroseconds] / (double)[fastTime userMicroseconds];
	NSLog(@"MPWUniqueString time: %d (%g ns/iter) stringtable time: %d (%g ns/iter)",[slowTime userMicroseconds],(1000.0*[slowTime userMicroseconds])/LOOKUP_COUNT,[fastTime userMicroseconds],(1000.0*[fastTime userMicroseconds])/LOOKUP_COUNT);
	NSLog(@"MPWUniqueString vs. string table lookup time ratio: %g",ratio);
	NSAssert2( ratio > 3.3 ,@"ratio of small string table to MPWUniqueString (NSMapTable) %g < %g",
				ratio,3.3);   
}
#endif

+(void)testFailedLookupGetsDefaultValue
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	char *key="something not in table";
	id defaultResult=@"my default result";
	INTEXPECT(0, [table objectForCString:key] , @"should not have found anything" );
	[table setDefaultValue:defaultResult];
	IDEXPECT(defaultResult, [table objectForCString:key] , @"should have found the default result" );
}

+(void)testOffsetLookup
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	INTEXPECT( 0, [table offsetForCString:"Help"],@"offset of first element" );
	INTEXPECT( 1, [table offsetForCString:"Marcel"],@"offset of second element" );
	INTEXPECT( 2, [table offsetForCString:"me"],@"offset of third element" );
	INTEXPECT( -1, [table offsetForCString:"myself"],@"offset of element not in table" );
}

+(void)testReplaceObject
{
	MPWSmallStringTable *table=[self _testCreateTestTable];
	INTEXPECT( [table offsetForCString:"Help"], 0,@"offset of first element" );
	IDEXPECT([table objectForKey:@"Help"], @"Value for Help", @"after replacing");
	[table setObject:@"other object" forKey:@"Help"];
	IDEXPECT([table objectForKey:@"Help"], @"other object", @"after replacing");
	[table setObject:@"second object" forKey:@"me"];
	IDEXPECT([table objectForKey:@"me"], @"second object", @"after replacing");
}

+(void)testLongerKeys
{
	NSArray *keys=[NSArray arrayWithObject:@"AudioList"];
	NSArray *values=[NSArray arrayWithObject:@"Value"];
	MPWSmallStringTable *table=[[[self alloc] initWithKeys:keys values:values ] autorelease];
	IDEXPECT([table objectForKey:@"AudioList"], @"Value", @"before replacing");
	[table setObject:@"new" forKey:@"AudioList"];
	IDEXPECT([table objectForKey:@"AudioList"], @"new", @"after replacing");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testSimpleCStringLookup",
			@"testSimpleNSStringLookup",
			@"testSimpleCStringLengthLookup",
			@"testLookupViaMacro",
#if FULL_MPWFOUNDATION			
			@"testLookupFasterThanNSDictionary",
			@"testLookupFasterThanMPWUniqueString",
#endif			
			@"testFailedLookupGetsDefaultValue",
			@"testKeyAtIndex",
			@"testOffsetLookup",
			@"testReplaceObject",
			@"testLongerKeys",
			nil];
}

@end

