/* NSObjectAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "NSObjectAdditions.h"
#import <objc/objc.h>
#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )
#import <objc/runtime.h>
#else
#import <objc/objc-class.h>
#endif

#ifdef Darwin
#endif

#import <AccessorMacros.h>
#import "MPWByteStream.h"

//#import "Foundation/NSDebug.h"


@implementation NSObject(FramweworkPathAdditions)

+(NSString*)frameworkPath:(NSString*)aPath
{
    return [[[NSBundle bundleForClass:self] resourcePath] stringByAppendingPathComponent:aPath];
}

+(NSData*)frameworkResource:(NSString*)aPath category:(NSString*)category
{
	NSBundle *bundle=[NSBundle bundleForClass:self];
	id path = [bundle pathForResource:aPath ofType:category];
	if ( path ) {
#ifdef GS_API_LATEST
        return [NSData dataWithContentsOfFile:path error:nil]; 
#else
        return [NSData dataWithContentsOfFile:path options:NSDataReadingMapped error:nil]; 
#endif
	} else {
		[NSException raise:@"ResourceUnavailable" format:@"Couldn't find resource '%@' of type '%@' (nil path) for bundle '%@' class %@",aPath,category,bundle,self];
		return nil;
	}
}

-(NSData*)frameworkResource:(NSString*)aPath category:(NSString*)category
{
    return [[self class] frameworkResource:aPath category:category];
}


@end

@implementation NSObject(initializationHelpers)

-(instancetype)initWithDictionary:(NSDictionary *)dict
{
    self=[self init];
    for ( NSString *key in [dict allKeys]) {
        [self setValue:dict[key] forKey:key];
    }
    return self;
}

-(instancetype)with:(void (^)(NSObject *self))block {
    if ( block && self) {
        block(self);
    }
    return self;
}

+(instancetype)with:(void (^)(NSObject *self))block {
    return [[self new] with:block];
}


@end

@implementation NSObject(ivarAccess)


+(void)addIvarNamesForCurrentClassToArray:(NSMutableArray*)names
{
	unsigned int i,count=0;
	Ivar* ivars=class_copyIvarList( self, &count );
	for ( i=0;i<count;i++) {
		[names addObject:[NSString stringWithUTF8String:ivar_getName( ivars[i]) ]];
	}
	free(ivars);
}

+(NSString*)ivarNameAtOffset:(int)ivarOffset
{
	unsigned int i,count=0;
	NSString *name=nil;
	Ivar* ivars=class_copyIvarList( self, &count );
	for ( i=0;i<count;i++) {
		if ( ivar_getOffset(ivars[i]) == ivarOffset ) {
			name= [NSString stringWithUTF8String:ivar_getName( ivars[i]) ];
			break;
		}
	}
	free(ivars);
	return name;
}


+(NSMutableArray*)allIvarNames
{
    Class class=self;
    Class superclass=[class superclass];
    NSMutableArray *ivarlist;

    if ( superclass ) {
        ivarlist = [superclass allIvarNames];
        [class addIvarNamesForCurrentClassToArray:ivarlist];
        return ivarlist;
    } else {
        return [NSMutableArray array];
    }
}

+(NSMutableArray*)ivarNames
{
    Class class=self;
    NSMutableArray *ivarlist=[NSMutableArray array];
    [class addIvarNamesForCurrentClassToArray:ivarlist];
    return ivarlist;
}


+(NSString*)ivarNameAtOffset:(int)ivarOffset orIndex:(int)index
{
    NSString* name=[self ivarNameAtOffset:ivarOffset];
    if ( !name ) {
        name = [NSString stringWithFormat:@"unnamed_%d",index];
    }
    return name;
}

+(NSString*)ivarNameForVarPointer:(const void*)address orIndex:(int)index ofInstance:(const void*)instaddr
{
    return [self ivarNameAtOffset:(int)(address-instaddr) orIndex:index];
}

-(NSString*)ivarNameForVarPointer:(const void*)address orIndex:(int)index
{
    return [object_getClass(self) ivarNameAtOffset:(int)(address-(const void*)self) orIndex:index];
}

@end

@implementation NSDictionary(ivarAccess)

+(NSString*)ivarNameAtOffset:(int)ivarOffset orIndex:(int)index
{
    if ( index == 1 ) {
        return @"count";
    } else if ( index > 1 ) {
        int isVal = index & 1;
        return isVal ? @"value" : @"key";
    } else {
        return [super ivarNameAtOffset:ivarOffset orIndex:index];
    }
}

-(instancetype)concat:(NSDictionary*)other
{
    NSMutableDictionary *combined=[NSMutableDictionary dictionaryWithDictionary:self];
    for (id key in [other keyEnumerator]) {
        combined[key]=other[key];
    }
    return combined;
}


@end

@implementation NSArray(additions)

+(NSString*)ivarNameAtOffset:(int)ivarOffset orIndex:(int)index
{
    if ( index == 1 ) {
        return @"count";
    } else if ( index > 1 ) {
        return @"arrayelement";
    } else {
        return [super ivarNameAtOffset:ivarOffset orIndex:index];
    }
}

@end

@implementation NSData(concat)

-concat:other
{
    NSMutableData *combined = [self mutableCopy];
    [combined appendData:[other asData]];
    return [combined autorelease];
}

@end

@implementation NSObject(memberOfSet1)

-(id)memberOfSet:(NSSet*)aSet
{
    return [aSet member:self];
}

@end

@implementation NSObject(stackCheck)


+(BOOL)isPointerOnStackAboveMe:(void*)ptr within:(long)maxDiff
{
    void *roughlyMyFrame = &_cmd;
    long differenceFromPtr = ptr - roughlyMyFrame;
    return differenceFromPtr > 0 && differenceFromPtr < maxDiff;
}

+(BOOL)isPointerOnStackAboveMe:(void*)ptr
{
    return [self isPointerOnStackAboveMe:ptr within:1000];
}


+(id)isPointerOnStackAboveMeForST:(void*)ptr
{
    return @([self isPointerOnStackAboveMe:ptr]);
}

@end


@implementation NSObject(stprocess)


-main:args
{
    return @(0);
}

-Stdout
{
    return [MPWByteStream Stdout];
}


-(int)runWithStdin:(id <StreamSource>)source Stdout:(MPWByteStream*)target
{
    [[target do] println:[self each]];
    return 0;
}

+(int)runWithStdin:(id <StreamSource>)source Stdout:(MPWByteStream*)target
{
    [[[self new] autorelease] runWithStdin:source Stdout:target];
    return 0;
}

+(int)main:args
{
    return [[[[[self alloc] init] autorelease] main:args] intValue];
}

+(int)mainArgc:(int)argc argv:(char**)argv
{
    NSMutableArray *args=[NSMutableArray array];
    [NSClassFromString(@"MPWBlockContext") class];            //
    for (int i=0;i<argc;i++) {
        [args addObject:@(argv[i])];
    }
    return [self main:args];
}


@end


#import "DebugMacros.h"

@interface NSObjectIvarAcccessTesting : NSObject { id a; int b; float c; NSString *d;id f; }
@end

@implementation NSObject(addressKey)

-addressKey
{
    long long address = (long long)(NSUInteger)self;
    return [NSString stringWithFormat:@"%llu",address];
}

@end

@implementation NSObject(NSDebugEnabled)

static int debugLevel=0;

intAccessor( debugLevel, setDebugLevel )

@end

@implementation NSObjectIvarAcccessTesting : NSObject

+(void)testIvarNames
{
	IDEXPECT( [NSObject allIvarNames], ([NSArray array]), @"NSObject has no visible ivars");
	IDEXPECT( [self allIvarNames], ([NSArray arrayWithObjects:@"a",@"b",@"c",@"d",@"f",nil]), @"ivar names");
}

-(char*)addressOfA  { return (char*)&a; };
-(char*)addressOfB  { return (char*)&b; };
-(char*)addressOfC  { return (char*)&c; };
-(char*)addressOfD  { return (char*)&d; };
// -(char*)addressOfE  { return (char*)&e; };
-(char*)addressOfF  { return (char*)&f; };

+(void)testIvarAtOffset
{
	id tester=[[self new] autorelease];
	
	IDEXPECT( [tester ivarNameForVarPointer:[tester addressOfA] orIndex:1],  @"a", @"first ivar" );
	IDEXPECT( [tester ivarNameForVarPointer:[tester addressOfB] orIndex:2],  @"b", @"second ivar" );

//	IDEXPECT( [self ivarNameAtOffset:((char*)&b - (char*)self)], @"b" ,@"name of second ivar");
}



+testSelectors
{
	return @[
			@"testIvarNames",
			@"testIvarAtOffset",
			];
}

@end

@interface NSDictionaryAdditionsTesting : NSObject @end
@implementation NSDictionaryAdditionsTesting

+(void)testConcatDicts
{
    NSDictionary *a=@{ @"a": @(3) };
    NSDictionary *b=@{ @"b": @(12) };
    NSDictionary *combined = [a concat:b];
    INTEXPECT( combined.count,2, @"elements");
    IDEXPECT(combined[@"a"],@(3), @"from a");
    IDEXPECT(combined[@"b"],@(12), @"from a");

}

+testSelectors
{
    return @[
        @"testConcatDicts",
    ];
}

@end
