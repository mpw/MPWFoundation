/* MPWSubData.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "MPWSubData.h"
#import "CodingAdditions.h"
#import <MPWObject.h>
//#import <MPWFoundation/bytecoding.h>
#import "DebugMacros.h"
#include <objc/runtime.h>

@interface NSObject(validate)

-(void)validate;

@end

@interface NSString(fastCString)

-(const char*)_fastCStringContents:(BOOL)something;

@end

@interface NSData (PrivateAPI)
- (id) initWithBytes: (void *)bytes
              length: (unsigned int) length
                copy: (BOOL) copy
        freeWhenDone: (BOOL) free
          bytesAreVM: (BOOL) vm;
@end

@implementation MPWSubData


boolAccessor( mustUnique, setMustUnique )

+(void)inititialize
{
	[MPWObject initialize];
}

-(BOOL)isMPWObject { return YES; }

#ifdef GNUSTEP

//#warning have to redefine class for MPWSubData


-(Class)class
{
	return object_getClass(self);
}

+allocFromZone:(NSZone*)zone
{
	return NSAllocateObject( self, 0, zone );
}

+alloc
{
	return NSAllocateObject( self, 0, NSDefaultMallocZone());
}

#endif

+allocWithZone:(NSZone*)zone
{
	return NSAllocateObject( self, 0, zone );
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

-(long)longValue
{
	long offset=0;
	long value=0;
	int sign=1;
	const char *bytes=myBytes;
	while ( offset < myLength && isspace( bytes[offset] ) ) {
		offset++;
	}
	if ( offset < myLength && bytes[offset] == '-' ) {
		sign=-1;
		offset++;
	} else if ( offset < myLength && bytes[offset] == '+' ) {
		offset++;
	}
	while ( offset < myLength && isdigit( bytes[offset] ) ) {
		value=value*10 + (bytes[offset++]-'0');
	}
	return value * sign;

}

-(int)intValue
{
    return (int)[self longValue];
}

-(void*)mutableBytes
{
    return (void*)[self bytes];
}

-initWithData:(NSData*)data bytes:(const char*)bytes length:(long)len
{
#ifndef GNUSTEP
	self = [super init];
#else
#warning cannot do [super init] in an NSString subclass in GNUStep
#endif
	[self reInitWithData:data bytes:bytes length:len];
    return self;   
}

#ifndef GNUSTEP

-(CFStringEncoding)cfStringEncoding
{
	return  kCFStringEncodingUTF8;
}


-copyWithZone:(NSZone*)aZone
{
    return (id)CFStringCreateWithBytes( NULL, myBytes , myLength, [self cfStringEncoding], NO);
}

#else

-copyWithZone:(NSZone*)aZone
{
    return [[NSString alloc] initWithString:self];
}

#endif

-reInitWithData:(NSData*)data bytes:(const char*)bytes length:(long)len
{
	if ( data != nil ) {
		if ( myData != data ) {
			[myData release];
			myData=[data retain];
		}
	} else {
		[NSException raise:@"subdata (re-)initialized with nil data" format:@"subdata (re-)initialized with nil data"];
    }
	if ( interned && myBytes ) {
		interned=NO;
		free( (void*)myBytes);
	}
    myBytes=bytes;
    myLength=len;
    return self;
}

/*
-(unsigned)hash
{
    return hashCStringLen(  myBytes, myLength  );
}
*/

-(unichar)characterAtIndex:(NSUInteger)index
{
    if ( index < myLength ) {
        return ((unsigned char*)myBytes)[index];
    } else {
        [NSException raise:@"OutOfRangeSubscript" format:@"subscript %ld greater than length %ld of %@/%p",
            (long)index,myLength,[self class],self];
        return 0;
    }
}

-(BOOL)isEqual:other
{
    if ( self == other ) {
        return YES;
    }
	if ( other  ) {
		long otherLen=[other length];
		const void *otherBytes=[other bytes];
		return otherLen==myLength &&
		((otherBytes==myBytes) || !bcmp( [other bytes],myBytes, myLength ));
	}
	if ( [other respondsToSelector:@selector(length)] &&  myLength == [other length] ) {
		return [self compare:other] == 0;
	} else {
		return NO;
	}	
}

-(const char *)_fastCStringContents:(BOOL)flag
{
	if (!flag) {
		return myBytes;
	} else {
		return NULL;
	}
}

-(const void*)bytes
{
    return myBytes;
}

-(const char*)cString
{
    return [[[self copy] autorelease] cString];
}

-(void)getCharacters:(unichar*)buf range:(NSRange)range
{
    if ( range.location + range.length <= myLength ) {
        int i;
        for (i=0;i<range.length;i++) {
            buf[i]=((unsigned char*)myBytes)[i+range.location];
        }
    } else {
        [NSException raise:@"OutOfRange" format:@"range (%ld,%ld) out of range (%ld)",(long)range.location,(long)range.length,(long)myLength];
    }
}

#if NS_BLOCKS_AVAILABLE
- (void) enumerateByteRangesUsingBlock:(void (^)(const void *bytes, NSRange byteRange, BOOL *stop))block
{
    BOOL stop=0;
    block( myBytes, NSMakeRange(0, myLength),&stop);
}
#endif


-(void)removeFromCache:aCache
{
//	[self intern];
}

-(void)intern
{
	if ( !interned && myData && myBytes ) {
		void *buffer=malloc( myLength+1 );
		memcpy(buffer, myBytes, myLength );
		interned=YES;
		myBytes=buffer;
		[myData release];
		myData=nil;
	}
}
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

-(void)getCString:(char*)buffer maxLength:(NSUInteger)len
{
	long copyLen=MIN(len,myLength);
	memcpy(buffer,myBytes,copyLen);
}

-(NSUInteger)cStringLength
{
    return myLength;
}

#pragma clang diagnostic pop

-(void)validate
{
	return;
#if 0	
	const unsigned char *theBytes=myBytes;
    const unsigned char *start=[myData bytes];
    const unsigned char *end=start+[myData length];
    const unsigned char *myEnd=myBytes+myLength;
	if ( !interned ) {
		NSAssert1( myData != nil, @"original data must be non-zero",nil);
		NSAssert1( start != NULL || myLength==0, @"byte spointer must be non-zero if non-zero length",nil);
		NSAssert3( theBytes >= start && theBytes<=end,@"sub-data start out-of-range: %x %x %x" ,start,myBytes,end);
		NSAssert3( myEnd >= start && myEnd<=end,@"sub-data end out-of-range: %x %x %x" ,start,myBytes,end); 
	}
#endif	
}

-(NSUInteger)length
{
    return myLength;
}

-asData
{
    return self;
}


-originalData
{
    return myData;
}

-(void)dealloc
{
//    NSLog(@"data %x/%@ retainCount %d, (self len=%d, dlen=%d)",myData,[myData class],[myData retainCount],myLength,[myData length]);
    [myData release];
	if (interned) {
		free( (void*)myBytes);
	}
    [super dealloc];
}

-stringValue
{
    return [[self copy] autorelease];
}

-stringRepresentation
{
	return [self stringValue];
}


-description
{
    if ( myLength > 70000 ) {
        char start[3]="  ";
        char end[3]="  ";
        strncpy( start, myBytes, 2 );
        strncpy( end, myBytes+myLength-2,2);
        return [NSString stringWithFormat:@"Data with %ld bytes, start '%.2s' end '%.2s'",
            myLength,start,end];
    } else {
        return [self stringValue];
    }
}

-(void)writeOnByteStream:stream
{
    [stream appendBytes:myBytes length:myLength];
}

-(unsigned long)offset
{
    return (unsigned char*)myBytes - (unsigned char*)[myData bytes];
}

-replacementObjectForCoder:(NSCoder*)aCoder
{
    id replacement=self;
    if ( interned || mustUnique ||
         ([myData retainCount] == 1 && ![NSStringFromClass( [myData class]) isEqual:@"NSPageData"])
          /* && [myData isKindOfClass:[NSData class]] */ ) {
        long offset = [self offset];
        if ( [myData isKindOfClass:[self class]] ) {
            MPWSubData *mySub=(MPWSubData*)myData;
            id orig=[mySub originalData];
            offset += [mySub offset];
            replacement = [[[[self class] alloc] initWithData:orig bytes:[orig bytes]+offset length:myLength] autorelease];
            replacement =  [replacement replacementObjectForCoder:aCoder];
        } else  {
            replacement = [NSData dataWithBytes:myBytes length:myLength];
        }
    }
    return replacement;
}

-(void)encodeWithCoder:(NSCoder*)aCoder
{
    long offset = [self offset];
    encodeVar( aCoder, myData );
    //    [aCoder encodeValueOfObjCType:@encode(typeof(offset)) at:&offset withName:"offset"]
    encodeVar( aCoder, offset );
    encodeVar( aCoder, myLength );
}

-initWithCoder:(NSCoder*)aCoder
{
    int offset;
//    NSLog(@"MPWSubData: initWithCoder:");
    decodeVar( aCoder, myData );
	NSAssert1( myData != nil, @"decoded data is nil!",nil );
	[myData validate];
//   NSLog(@"MPWSubData: initWithCoder, myData %x retainCount= %d",myData,[myData retainCount]);
    decodeVar( aCoder, offset );
    decodeVar( aCoder, myLength );
    myBytes = [myData bytes] + offset;
    return self;
}

-classForCoder
{
    return object_getClass( self);
}

@end

@implementation NSData(mpwsubdata)

-stringValue
{
    NSString *s=nil;
    @try {
        s=[[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding] autorelease];
    } @catch ( id e) {
    }
    if (!s) {
        s=[[[NSString alloc] initWithData:self encoding:NSISOLatin1StringEncoding] autorelease];
    }
    return s; 
}

-(MPWSubData*)mpwSubdataWithRange:(NSRange)theRange
{
//    return [[MPWSubData alloc] initWithData:self bytes:self.bytes+theRange.location length:theRange.length];
    return [[[MPWSubData alloc] initWithData:self bytes:self.bytes+theRange.location length:theRange.length] autorelease];
}

@end


@implementation MPWSubData(testing)

+_subDataWithString:(char *)string 
{
	long len=strlen(string);
	NSData *data = [NSData dataWithBytes:string length:len];
	MPWSubData *subData = [[[MPWSubData alloc] initWithData:data bytes:[data bytes] length:len] autorelease];
	return subData;
}


+(void)testSubDataProtectsAgainstNilOriginalData
{
	id subData = nil;
	NS_DURING
		subData = [[MPWSubData alloc] initWithData:nil bytes:NULL length:3];
	NS_HANDLER
	NS_ENDHANDLER
	NSAssert1( subData == nil ,@"subData should not have initialized",nil);
}

+(void)testSubDataIntValue
{
	INTEXPECT( [[self _subDataWithString:"-4"] intValue] , -4, @"negative subdata");
	INTEXPECT( [[self _subDataWithString:"4"] intValue] , 4, @"positive subdata");
}


+(void)testSubDataLongValue
{
	INTEXPECT( [[self _subDataWithString:"-5000000000"] longValue] , -5000000000, @"negative subdata");
	INTEXPECT( [[self _subDataWithString:"5000000000"] longValue] , 5000000000, @"positive subdata");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
			@"testSubDataProtectsAgainstNilOriginalData",
			@"testSubDataIntValue",
            @"testSubDataLongValue",
//            @"testSubDatasHaveSamePointer",
		nil];
}


@end
#ifndef RELEASE

#endif
