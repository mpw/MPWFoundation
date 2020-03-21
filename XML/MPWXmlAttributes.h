/* MPWXmlAttributes.h Copyright (c) Marcel P. Weiher 1998-2008, All Rights Reserved,
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
THE POSSIBILITY OF SUCH DAMAGE.  */


#import <Foundation/Foundation.h>
#import "MPWMAXParser.h"


@interface MPWXMLAttributes : NSObject <NSXMLAttributes>
{
	NSInteger		_retainCount;
	id				builtinKeys[6];
	id				builtinValues[6];
	id				builtinNamespace[6];
	id*				keys;
	id*				values;
	id*		namespaces;
	NSInteger		attrCount;
	NSInteger		attrCapacity;
}


-(id)objectForKey:(id)aKey;						//	retrieve first value whose local name matches aKey
-(id)objectForUniqueKey:(id)aKey;				//		assumes keys have been uniqued
-(id)objectsForKey:(id)aKey;					//	retrieve all values whose local name matches aKey
-(id)objectsForUniqueKey:(id)aKey;				//		assumes keys have been uniqued
-(id)objectsForUniqueKey:(id)aKey namespace:aNamespace;				//		assumes keys have been uniqued
-(id)objectForCaseInsensitiveKey:(id)aKey;		//	retrieve first value whose local name matches aKey ignoring case
-(id)objectAtIndex:(NSUInteger)anIndex;			//	get value by position
-(id)keyAtIndex:(NSUInteger)anIndex;
-(NSUInteger)count;
-(NSDictionary*)asDictionaryExcludingKeys:(NSSet*)excludedKeys;
-(NSDictionary*)asDictionary;
-(NSArray*)allValues;
-(NSArray*)allKeys;
-(id*)_pointerToObjects;
-(id)lastObject;
-(BOOL)isLeaf;


-(void)setValue:anObject forAttribute:aKey;
-(void)removeAllObjects;
-(void)pop:(long)n;
-(void)copyKeysTo:(MPWXMLAttributes*)copy;

@end
