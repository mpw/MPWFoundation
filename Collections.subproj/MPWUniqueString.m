/* MPWUniqueString.m
   based on (NSString_Tokens.m Copyright (c) 1998-2011 by Marcel Weiher, All Rights Reserved.


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

*/


#import <Foundation/NSMapTable.h>
#import <Foundation/NSData.h>
#import <ctype.h>
#import <string.h>
#import <stdlib.h>
#import <stdio.h>
#import "MPWUniqueString.h"
#import <MPWFoundation/bytecoding.h>
#import "MPWSubData.h"

static NSString* empty1( NSMapTable *t, const void *p) { return @"";}
static void empty2( NSMapTable *t, void *p) {}
static void empty3( NSMapTable *t, const void *p) {}

typedef struct {
	const char *str;
	int len;
} pstr;


@interface NSString(fastCString)

-_fastCStringContents:(BOOL)something;

@end

#if LIB_FOUNDATION

@implementation NSString(libFoundationNeedsCharactersNoCopy)

-initWithCharactersNoCopy:(unichar*)unichars length:(unsigned int)newLen freeWhenDone:(BOOL)shouldFree
{
	NSString *newString;
	[self release];
	newString =  [[NSString alloc] initWithCharacters:unichars length:newLen];
	if ( shouldFree ) {
		free( unichars);
	}
	return newString;
}

@end

#endif

@interface MPWUniqueString(pstring)
-(pstr*)pstring;
@end

@implementation MPWUniqueString 


-initWithCString:(const char*)cStr length:(NSUInteger)newLen
{
	char *buffer=malloc( newLen+ 2 );
	char *dest=buffer;

	[super init];
	data=buffer;
	len=newLen;
	while ( newLen-- ) {
		*dest++ = *cStr++;
	}
	*dest=0;
    hash=[super hash];
	return self;
}

-(NSUInteger)hash
{
	return hash;
}

-(BOOL)isEqual:other
{
	if ( other == self ) {
		return YES;
	} else {
		if ( isa == *(Class*)other ) {
			return NO;
		} else {
			int otherLen=[other length];
			if ( len == otherLen ) {
				const char *otherCString=(const char*)[other _fastCStringContents:NO];
				if ( otherCString ) {
					return !strncmp( data, otherCString, len );
				} else {
					return [self compare:other] == 0;
				}
			} else {
				return NO;
			}
		}

	}
}

-(const char *)_fastCStringContents:(BOOL)flag
{
	if (!flag) {
		return data;
	} else {
		return NULL;
	}
}

-(const char*)cString
{
	return data;
}

-(unichar)characterAtIndex:(unsigned)index
{
    return data[index];
}

- (void)getCString:(char*)buffer maxLength:(unsigned int)maxLength
  range:(NSRange)aRange remainingRange:(NSRange*)leftoverRange
{
	if ( maxLength > aRange.length  ) {
		maxLength = aRange.length;
	}
	if ( maxLength > len - aRange.location ) {
		maxLength = len - aRange.location;
	}
	if ( maxLength > 0 ) {
		memcpy(buffer, data+aRange.location, maxLength);
	} else {
		maxLength = 0;
	}
	if (leftoverRange) {
		leftoverRange->location = aRange.location + maxLength;
		leftoverRange->length = len - leftoverRange->location;
    }
}


-(NSUInteger)length
{
	return len;
}

-(NSUInteger)cStringLength
{
	return len;
}

-uniqueString
{
	return self;
}

-retain
{
	return self;
}

-(void)release
{
}

-(void)dealloc
{
	return;
	[super dealloc];
}

 -(pstr*)pstring
 {
	return (pstr*)&data;
 }

-(void)writeOnByteStream:aStream
{
	[aStream appendBytes:data length:len];
}

-copyWithZone:(NSZone*)aZone
{
    return self;
}

@end

/* new case insensitive hash function */
static NSUInteger _pstrHash(NSMapTable *table, const void *aPString)
{
	pstr *s1=(pstr*)aPString;

    return hashCStringLen( (const unsigned char*)s1->str, s1->len );
}



static BOOL _pstrEqual( NSMapTable *table, const void *p1,const void *p2)
{
	pstr *s1=(pstr*)p1,*s2=(pstr*)p2;
	if ( s1->len == s2->len  && !strncmp( s1->str,s2->str, s1->len )) {
//		fprintf(stderr,"  '%.*s' == '%.*s'\n",
//						s1->len,s1->str,s2->len,s2->str);
		return YES;
	} else {
//		fprintf(stderr,"  '%.*s' != '%.*s'\n",
//						s1->len,s1->str,s2->len,s2->str);
		return NO;
	}
}

static void _retain(NSMapTable *table, const void *p)
{
    [(id)p retain];
}

static void _release(NSMapTable *table, void *p)
{
    [(id)p release];
}


static NSMapTable *_createTokenMapTable( )
{
    NSMapTableKeyCallBacks keyCallBacks;
    NSMapTableValueCallBacks valueCallBacks;

    keyCallBacks.hash = &_pstrHash;
    keyCallBacks.isEqual = &_pstrEqual;
    keyCallBacks.retain = &empty3;
    keyCallBacks.release = &empty2;
    keyCallBacks.describe = &empty1;
    keyCallBacks.notAKeyMarker=(const void*)-1;

    valueCallBacks.retain=&_retain;
    valueCallBacks.release=&_release;
    valueCallBacks.describe=&empty1;

    return NSCreateMapTable( keyCallBacks, valueCallBacks, 50 );
}

static void _insertNSString( NSMapTable *table, MPWUniqueString *string )
{
    NSMapInsertIfAbsent( table, [string pstring], string );
}


static NSMapTable *_tokenTable() {
    static NSMapTable * theTable=NULL;
    if ( !theTable ) {
        theTable = _createTokenMapTable();
    }
    return theTable;
}

MPWUniqueString *MPWUniqueStringWithCString( const char *string, int len )
{
    NSMapTable *table=_tokenTable();
    MPWUniqueString *result;
	pstr s = { string, len };
//	fprintf(stderr,"trying to find: '%.*s'\n",len,string);
    if ( nil == (result = NSMapGet( table, &s )) ) {
//		fprintf(stderr,"have to insert: '%.*s'\n",len,string);
        result = [[MPWUniqueString alloc]
							initWithCString:string length:len];
        _insertNSString( table, result );
    } else {
//		fprintf(stderr,"did NOT have to insert: '%.*s'\n",len,string);

	}
    return result;
}

MPWUniqueString *MPWUniqueStringWithUnichars( const unichar *string, int len )
{
    unsigned char str[len];
    int i;
    for (i=0;i<len;i++){
        str[i]=string[i];
    }
    return MPWUniqueStringWithCString( (const char*)str, len );
}

MPWUniqueString *MPWUniqueStringWithString( id string )
{
	return MPWUniqueStringWithCString( [string cString], [string cStringLength] );
}

@implementation NSString(unique)

-uniqueString
{
	return MPWUniqueStringWithString( self );
}

@end

@implementation MPWSubData(unique)

-uniqueString
{
    return MPWUniqueStringWithCString( [self bytes], [self length] );
}


@end

