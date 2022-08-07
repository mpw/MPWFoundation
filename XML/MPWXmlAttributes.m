/* MPWXmlAttributes.m Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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

, created  on Mon 26-Oct-1998 */

#import "MPWXmlAttributes.h"
#import "MPWTagHandler.h"
#import <MPWByteStream.h>

@implementation MPWXMLAttributes

//CACHING_ALLOC( attributes, 10, NO )




-(void)pop:(long)n
{
	n=MIN(n,attrCount);
    long remaining=attrCount-n;
    id *keyPtr=keys+remaining;
    id *valPtr=values+remaining;
    id *namespacePtr=namespaces+remaining;
    id *keyLimit=keys+attrCount;
    while ( keyPtr < keyLimit) {
        if ( *keyPtr ) {
            [*keyPtr release];
            *keyPtr=nil;
        }
        if ( *valPtr ) {
            [*valPtr release];
            *valPtr=nil;
        }
        *namespacePtr=nil;
        keyPtr++;
        valPtr++;
        namespacePtr++;
    }
    attrCount-=n;
}


-(void)removeAllObjects
{
	[self pop:attrCount];
}

-keyAtIndex:(NSUInteger)anIndex
{
	return keys[anIndex];
}

-objectAtIndex:(NSUInteger)anIndex
{
	return values[anIndex];
}

-namespaceAtIndex:(NSUInteger)anIndex
{
	return namespaces[anIndex];
}

-lastObject
{
	return attrCount > 0 ? [self objectAtIndex:attrCount-1] : nil;
}

-(NSDictionary*)asDictionaryExcludingKeys:(NSSet*)excludedKeys;
{
	long i,max;
	NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithCapacity:[self count] - [excludedKeys count]];
	for ( i=0,max=[self count];i<max; i++ ) {
		if ( ! [excludedKeys containsObject:keys[i]] && values[i] && keys[i] ) {
			[dict setObject:values[i] forKey:keys[i]];
		}
	}
	return dict;
}

-(NSDictionary*)asDictionary
{
	return [self asDictionaryExcludingKeys:nil];
}


-(id*)_pointerToObjects
{
	return values;
}

-init
{
    self = [super init];
//	NSLog(@"init %p",self);

	attrCount=0;
	memset( builtinKeys, 0, sizeof builtinKeys );
	memset( builtinValues, 0, sizeof builtinValues );
	memset( builtinNamespace, 0, sizeof builtinNamespace );
	attrCapacity=6;
	keys=builtinKeys;
	values=builtinValues;
	namespaces=builtinNamespace;
    return self;
}

-objectsForKey:aKey
{
	NSMutableArray *valuesForKey=[NSMutableArray array];
	int i;
	for (i=0; i<attrCount;i++) {
		if ([aKey isEqual:keys[i]] ) {
			[valuesForKey addObject:values[i]];
		}
	}
	return valuesForKey;
}


-objectsForUniqueKey:aKey namespace:aNamespace
{
	NSMutableArray *valuesForKey=[NSMutableArray array];
	int i;
	for (i=0; i<attrCount;i++) {
		if ( aKey == keys[i] && (!aNamespace || aNamespace==namespaces[i])) {
			[valuesForKey addObject:values[i]];
		}
	}
	return valuesForKey;
}

-objectsForUniqueKey:aKey
{
	NSMutableArray *valuesForKey=[NSMutableArray array];
	int i;
	for (i=0; i<attrCount;i++) {
		if ( aKey == keys[i] ) {
			[valuesForKey addObject:values[i]];
		}
	}
	return valuesForKey;
}


-objectForKey:aKey
{
	int i;
	for (i=0; i<attrCount;i++) {
		if ( [aKey isEqual:keys[i]] ) {
			return values[i];
		}
	}
	return nil;
}

-objectForUniqueKey:aKey
{
	int i;
	for (i=0; i<attrCount;i++) {
		if ( aKey == keys[i] ) {
			return values[i];
		}
	}
	return nil;
}

-valueForKey:aKey
{
	return [self objectForKey:aKey];
}

-objectForUniqueKey:aKey namespace:aNamespace
{
	int i;
	for (i=0; i<attrCount;i++) {
		if ( aKey == keys[i] && ( (aNamespace==nil) || (aNamespace==namespaces[i])) ) {
			return values[i];
		}
	}
	return nil;
}

-(BOOL)isLeaf
{
	int i;
	for (i=0;i<attrCount;i++) {
		if ( keys[i] != MPWXMLPCDataKey && keys[i] != MPWXMLCDataKey ) {
			return NO;
		}
	}
	return YES;
}

-objectForCaseInsensitiveKey:aKey
{
	int i;
	for (i=0; i<attrCount;i++) {
		if ( [aKey caseInsensitiveCompare: (NSString*)keys[i]]== NSOrderedSame ) {
			return values[i];
		}
	}
	return nil;
}

-(NSArray*)allKeys
{
	return [NSArray arrayWithObjects:keys count:attrCount];
}

-(NSArray*)allValues
{
	return [NSArray arrayWithObjects:values count:attrCount];
}


-(NSUInteger)count
{
    return attrCount;
}

-(void)_freeBuffersIfAllocated
{
	if ( keys != builtinKeys )		free(keys);
	if ( values != builtinValues )	free(values);
	if ( namespaces != builtinNamespace )		free(namespaces);
}

-(void)_growCapacity
{
	long newCapacity = attrCapacity * 2;
	id *newKeys=ALLOC_POINTERS( (newCapacity+1)*sizeof(id) );
	id *newValues=ALLOC_POINTERS((newCapacity+1)*sizeof(id) );
	id *newNamespaces=ALLOC_POINTERS( (newCapacity+1)*sizeof(id) );
	memcpy( newKeys, keys, sizeof(id)*attrCount );
	memcpy( newValues, values, sizeof(id)*attrCount );
	memcpy( newNamespaces, namespaces, sizeof(id)*attrCount );
	[self _freeBuffersIfAllocated];
	keys=newKeys;
	values=newValues;
	namespaces=newNamespaces;
	attrCapacity=newCapacity;
}

-(void)setValueAndRelease:anObject forAttribute:aKey namespace:aNamespace 
{
	if ( attrCount+1 >= attrCapacity ) {
		[self _growCapacity];
	}
	if ( attrCount < attrCapacity ) {
		keys[attrCount]=[aKey retain];
		values[attrCount]=anObject;
		namespaces[attrCount]=aNamespace;
		attrCount++;
	} else {
		//-- do something?
	}
//	NSLog(@"%p setValue:%@ forKey:%@",self,anObject,aKey);
}

-(void)setValue:anObject forAttribute:aKey 
{
	[self setValueAndRelease:[anObject retain] forAttribute:aKey namespace:nil];
}


-(NSString*)combinedText
{
	NSMutableString* result=nil;
	int numTextFragments=0;
	int i;
	for (i=0;i<attrCount;i++) {
		if ( keys[i]==MPWXMLPCDataKey || keys[i]==MPWXMLCDataKey ) {
			numTextFragments++;
			switch (numTextFragments) {
				case 1:
					result=values[i];
					break;
				case 2:
					result=[NSMutableString stringWithString:result];
					//--- fall-through is intentional
				default:
					[result appendString:values[i]];
			}
		}
	}
	return result;
}

-(void)generateXmlOnto:aStream
{
//    [aStream writeEnumerator:[attrVals objectEnumerator] spacer:@" "];
}

-(void)writeOnByteStream:(MPWByteStream *)aStream
{
	int i;
	[aStream appendBytes:"{\n" length:2];
	[aStream indent];
	for (i=0; i< [self count]; i++ ) {
		[aStream writeObject:values[i] forKey:keys[i]];
	}
	[aStream outdent];
	[aStream writeIndent];
	[aStream appendBytes:"}" length:1];
}

-(NSString*)description
{
	id descr=[NSMutableString stringWithFormat:@"<%@/%p with values:\n",[self class],self];
	int i;
	for (i=0;i<attrCount;i++) {
		[descr appendFormat:@" attribute[%d] %@='%@' namespace: %p %@\n",i,keys[i],values[i],namespaces[i],[namespaces[i] namespaceString]];
	}
	[descr appendFormat:@">"];
	return descr;
}

-(void)copyKeysTo:(MPWXMLAttributes*)copy
{
	int i;
	for ( i=0;i<attrCount;i++) {
		id keyCopy=[keys[i] copy];
		id valueCopy=[values[i] copy];
		[copy setValueAndRelease:valueCopy forAttribute:keyCopy namespace:[namespaces[i] retain]];
		[keyCopy release];
		//		[valueCopy release];           
	}
}

-copyWithZone:(NSZone*)aZone
{
	id copy=[[[self class] allocWithZone:aZone] init];
	[self copyKeysTo:copy];
	return copy;
}

-(void)dealloc
{
//	NSLog(@"dealloc %p",self);
	[self removeAllObjects];
	[self _freeBuffersIfAllocated];
    [super dealloc];
}

- retain
{
    return retainMPWObject( (MPWObject*)self );
}

- (NSUInteger)retainCount
{
    return _retainCount+1;
}

- (oneway void)release
{
    releaseMPWObject((MPWObject*)self);
}

-keyEnumerator
{
	return [[self allKeys] objectEnumerator];
}

-(void)copyValueOfKey:(NSString*)xmlkey toObject:targetObject usingKey:(NSString*)targetKey
{
	id value=[self objectForKey:xmlkey];
	if ( value ) {
		[targetObject setValue:value forKey:targetKey];
	}
}

-(void)copyValueOfKey:xmlkey toObject:targetObject
{
	[self copyValueOfKey:xmlkey toObject:targetObject usingKey:xmlkey];
}

-(NSArray*)at:(NSString*)key
{
    return [self objectsForKey:key];
}


@end

#import "DebugMacros.h"


@implementation MPWXMLAttributes(testing)

+(void)testTextCombining
{
	MPWXMLAttributes* attrs=[[self new] autorelease];
	[attrs setValue:@"text" forAttribute:MPWXMLPCDataKey ];
	IDEXPECT( [attrs combinedText], @"text", @"one text fragment");
	[attrs setValue:@" and more" forAttribute:MPWXMLPCDataKey ];
	IDEXPECT( [attrs combinedText], @"text and more", @"one text fragment");
	[attrs setValue:@"not text" forAttribute:@"NOT-TEXT" ];
	IDEXPECT( [attrs combinedText], @"text and more", @"one text fragment");
}

+(void)testObjectForUniqueKey
{
	NSString *nonUniqueKey=[NSString stringWithCString:"TEXT" encoding:NSASCIIStringEncoding];
	MPWXMLAttributes* attrs=[[self new] autorelease];
	[attrs setValue:@"text" forAttribute:@"TEXT" ];
	IDEXPECT( [attrs objectForKey:@"TEXT"], @"text", @"plain objectForKey");
	IDEXPECT( [attrs objectForUniqueKey:@"TEXT"], @"text", @" objectForUniqueKey");
	IDEXPECT( [attrs objectForUniqueKey:nonUniqueKey], nil, @"objectForUniqueKey with equal but not identical");
	IDEXPECT( [attrs objectForKey:nonUniqueKey], @"text", @"objectForKey with equal but not identical");

}


+(void)testCopyKeys
{
	NSString *xmlkey=@"key";
	NSString *otherKey=@"key1";
	NSString *testValue=@"testValue";
	MPWXMLAttributes* attrs=[[self new] autorelease];
	NSMutableDictionary *resultDict=[NSMutableDictionary dictionary];
	[attrs setValue:testValue forAttribute:xmlkey ];
	EXPECTNIL( [resultDict objectForKey:xmlkey] ,@"target object value before copy");
	[attrs copyValueOfKey:xmlkey toObject:resultDict];
	IDEXPECT( [resultDict objectForKey:xmlkey], testValue, @"copied value");
	EXPECTNIL( [resultDict objectForKey:otherKey] ,@"target object other key value before copy");

	[attrs copyValueOfKey:xmlkey toObject:resultDict usingKey:otherKey];
	IDEXPECT( [resultDict objectForKey:xmlkey], testValue, @"copied value");

}

+(void)testByteStreaming
{
    MPWXMLAttributes* attrs=[[self new] autorelease];
    [attrs setValue:@"value1" forAttribute:@"key"];
    [attrs setValue:@"value2" forAttribute:@"key"];
    IDEXPECT( [MPWByteStream makeString:attrs], @"{\n    key: value1;\n    key: value2;\n}" ,@"serialize");
}

+(void)objectsForKey
{
    MPWXMLAttributes* attrs=[[self new] autorelease];
    [attrs setValue:@"value1" forAttribute:@"key"];
    [attrs setValue:@"value2" forAttribute:@"key"];
    IDEXPECT( [attrs objectsForKey:@"key"], (@[ @"value1", @"value2"]), @"getting multiple values")
}

+(void)testAtIsObjectsForKey
{
    MPWXMLAttributes* attrs=[[self new] autorelease];
    [attrs setValue:@"value1" forAttribute:@"key"];
    [attrs setValue:@"value2" forAttribute:@"key"];
    IDEXPECT( [attrs at:@"key"], (@[ @"value1", @"value2"]), @"getting multiple values for at:")
}

+testSelectors
{
	return @[
			@"testTextCombining",
			@"testObjectForUniqueKey",
			@"testCopyKeys",
            @"testByteStreaming",
            @"objectsForKey",
            @"testAtIsObjectsForKey",
			];
}

@end
