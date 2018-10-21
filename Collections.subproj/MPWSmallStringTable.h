//
//  MPWSmallStringTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 29/3/07.
//  Copyright 2007-2017 by Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPWObject.h"
#import "AccessorMacros.h"

typedef id (*LOOKUPIMP)(id, SEL, char*, int);


typedef struct {
    int index;
    int length;
    int offset;
    int next;
    
} StringTableIndex;

@interface MPWSmallStringTable : NSDictionary {
	int     __retainCount;
	int     flags;
	int     tableLength;
	unsigned char *table;
#if WINDOWS || LINUX
	id      *tableValues;
#else
	__strong  id *tableValues;
#endif
    StringTableIndex *tableIndex;
    int     *chainStarts;
    int     *tableOffsetsPerLength;
    int     maxLen;
	id      defaultValue;
	BOOL    caseInsensitive;
    
	@public
	LOOKUPIMP    __stringTableLookupFun;
}

//extern IMP __stringTableLookupFun;

-initWithKeys:(NSArray*)keys values:(NSArray*)values;

-(NSUInteger)count;
-objectForKey:(NSString*)key;
-objectAtIndex:(NSUInteger)anIndex;
-objectForCString:(const char*)cstr length:(int)len;
-objectForCString:(const char*)cstr;
-(int)offsetForCString:(const char*)cstr length:(int)len;
-(int)offsetForCString:(const char*)cstr;
-keyAtIndex:(NSUInteger)anIndex;
-(void)setObject:anObject forKey:aKey;
- (void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:(id)anObject;
-(int)offsetForKey:(NSString*)key;

idAccessor_h( defaultValue, setDefaultValue )

#define OBJECTFORSTRINGLENGTH( table, str, stlen )  (table->__stringTableLookupFun( table, @selector(objectForCString:length:) , (char*)str, (int)stlen ))
#define OBJECTFORCONSTANTSTRING( table, str )  OBJECTFORSTRINGLENGTH( table, str, (sizeof str) -1 )


@end
