//
//  MPWSmallStringTable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 29/3/07.
//  Copyright 2007-2012 by Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPWObject.h"
#import "AccessorMacros.h"

typedef struct {
    int index;
    int length;
    int offset;
    int next;
    
} StringTableIndex;

@interface MPWSmallStringTable : NSDictionary {
	int __retainCount;
	int	flags;
	int	tableLength;
	char *table;
#if WINDOWS || LINUX
	id *tableValues;
#else
	__strong  id *tableValues;
#endif
    StringTableIndex *tableIndex;
    int *chainStarts;
    int maxLen;
	id	defaultValue;
	BOOL caseInsensitive;
    
	@public
	IMP __stringTableLookupFun;
}

//extern IMP __stringTableLookupFun;

-initWithKeys:(NSArray*)keys values:(NSArray*)values;

-(NSUInteger)count;
-objectForKey:(NSString*)key;
-objectAtIndex:(NSUInteger)anIndex;
-objectForCString:(char*)cstr length:(int)len;
-objectForCString:(char*)cstr;
-(int)offsetForCString:(char*)cstr length:(int)len;
-(int)offsetForCString:(char*)cstr;

idAccessor_h( defaultValue, setDefaultValue )

#define OBJECTFORSTRINGLENGTH( table, str, stlen )  (table->__stringTableLookupFun( table, @selector(objectForCString:length:) , str, stlen ))
#define OBJECTFORCONSTANTSTRING( table, str )  OBJECTFORSTRINGLENGTH( table, str, (sizeof str) -1 )


@end
