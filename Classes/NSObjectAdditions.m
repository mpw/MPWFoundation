/* NSObjectAdditions.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "NSObjectAdditions.h"
#import <objc/objc.h>
#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )
#import <objc/runtime.h>
#else
#import <objc/objc-class.h>
#endif

#import <MPWFoundation/MPWUniqueString.h>
#ifdef Darwin
#endif

#import "AccessorMacros.h"


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
        return [NSData dataWithContentsOfFile:path options:NSDataReadingMapped error:nil]; 
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

@implementation NSObject(ivarAccess)

#if Darwin

#if __OBJC2__ || ( MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5 )
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


#else
+(NSString*)ivarNameAtOffset:(int)ivarOffset
{
    struct objc_class *class=self;
//    NSLog(@"going to find var at %d isa=%x",ivarOffset,isa);
    if ( ivarOffset >0 && ivarOffset < class->instance_size ) {
        int i;
//        NSLog(@"is within bounds, start check");
        while ( class ) {
//            NSLog(@"is->ivars = %x",class->ivars);
            if ( class->ivars ) {
//                NSLog(@"ivar-count = %d",class->ivars->ivar_count);
               for (i=0;i<class->ivars->ivar_count; i++ ) {
//                   NSLog(@"checking instvar %d",i);
                   if ( class->ivars->ivar_list[i].ivar_offset == ivarOffset ) {
                        const char *name =  class->ivars->ivar_list[i].ivar_name;
//                       NSLog(@"found var[%d] at %d",i,ivarOffset);
 //                       NSLog(@"called %s",name);
                        return MPWUniqueStringWithCString(name,strlen(name));
                    }
                }
            }
            class=class->super_class;
        }
    }
    return nil;
}

+(void)addIvarNamesForCurrentClassToArray:(NSMutableArray*)ivarlist
{	
	struct objc_class* class=(struct objc_class*)self;
	if ( class->ivars ) {
	int i;
	for (i=0;i<class->ivars->ivar_count; i++ ) {
		const char *name =  class->ivars->ivar_list[i].ivar_name;
		[ivarlist addObject:
		 MPWUniqueStringWithCString(name,strlen(name))];
	}
}
//    return ivarlist;
}


#endif

#else
#warning ivar access not implemented yet for gnu runtime!

#endif

+(NSMutableArray*)ivarNames
{
    Class class=self;
	Class superclass=[class superclass];
	NSMutableArray *ivarlist;
	
	if ( superclass ) {
		ivarlist = [superclass ivarNames];
		[class addIvarNamesForCurrentClassToArray:ivarlist];
		return ivarlist;
	} else {
		return [NSMutableArray array];
	}
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

@end

@implementation NSArray(ivarAccess)

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
@implementation NSObject(memberOfSet1)

-(id)memberOfSet:(NSSet*)aSet
{
    return [aSet member:self];
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
	IDEXPECT( [NSObject ivarNames], ([NSArray array]), @"NSObject has no visible ivars");
	IDEXPECT( [self ivarNames], ([NSArray arrayWithObjects:@"a",@"b",@"c",@"d",@"f",nil]), @"ivar names");
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
	return [NSArray arrayWithObjects:
			@"testIvarNames",
			@"testIvarAtOffset",
			nil];
}

@end

