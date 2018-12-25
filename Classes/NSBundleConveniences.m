//
//  NSBundleConveniences.m
//  MPWFoundation
//
//  Created by marcel on Fri Aug 31 2001.
/*  
    Copyright (c) 2001-2017 by Marcel Weiher.  All rights reserved.
*/
//

#import "NSBundleConveniences.h"
#import "NSStringAdditions.h"

@implementation NSBundle(Conveniences)

-(NSData*)resourceWithName:(NSString*)aName type:(NSString*)aType 
{
	NSString *path = [self pathForResource:aName ofType:aType];
	NSData *data=nil;
    if ( path ) {
#ifdef GS_API_LATEST
        data =  [NSData dataWithContentsOfFile:path];
#else
        data =  [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:NULL];
#endif
    } else {
        NSLog(@"couldn't find resource %@.%@ at '%@' bundlePath: '%@' resourcePath: '%@' bundle: %@",aName,aType,path,[self bundlePath],[self resourcePath],self);
    }
    return data;
}

+(NSData*)resourceWithName:(NSString*)aName type:(NSString*)aType forClass:(Class)class
{
	NSBundle *classBundle = [self bundleForClass:class];

    return [classBundle resourceWithName:aName type:aType];
}

+defaultFrameworkSearchPaths
{
	return [NSMutableArray arrayWithObjects:
		@"~/Library/Frameworks",
		@"/Library/Frameworks",
		@"/System/Library/Frameworks",
		nil];
}

static id frameworkSearchPaths=nil;

+frameworkSearchPaths
{
	if ( !frameworkSearchPaths ) {
		frameworkSearchPaths=[[self defaultFrameworkSearchPaths] retain];
	 }
	 return frameworkSearchPaths;
}

+(void)addFrameworkSearchPath:newPath
{
	[[self frameworkSearchPaths] addObject:newPath];
}


+frameworkPathForFrameworkName:(NSString*)frameworkName
{
	int i;
	id prefixes = [self frameworkSearchPaths];
	for ( i=0;i<[prefixes count];i++) {
		id path = [[NSString stringWithFormat:@"%@/%@.framework",[prefixes objectAtIndex:i],frameworkName] stringByStandardizingPath];
		if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
			return path;
		}
	}
	return nil;
}


+loadFramework:(NSString*)frameworkName
{
	NSBundle* bundle=[self bundleWithPath:[self frameworkPathForFrameworkName:frameworkName]];
	[bundle load];
	return bundle;
}

@end

@implementation NSObject(bundleConveniences)

-(NSData*)resourceWithName:(NSString*)aName type:(NSString*)aType
{
    Class class;
    for ( class=[self class]; class != (Class)nil; class=[class superclass] ) {
        id data = [NSBundle resourceWithName:aName type:aType forClass:class];
//        NSLog(@"tried to find %@.%@ in %@'s bundle: %x",aName,aType,class,data);
        if ( data ) {
            return data;
        }
    }
	NSLog(@"failed to find resource '%@.%@'",aName,aType);
    return nil;
}

@end

@interface MPWBundleTesting : NSObject
{}
@end
@implementation MPWBundleTesting
+(void)testSimpleResource
{
    NSString* expectedResource = @"This is a simple resource";
    NSString* resource = [[self resourceWithName:@"ResourceTest" type:@""] stringValue];
    NSAssert2( [resource isEqual:expectedResource], @"Got resource '%@', expected '%@'",
              resource,expectedResource);  (void)expectedResource; (void)resource;
}

+(NSArray*)testSelectors
{
    return [NSArray arrayWithObjects:@"testSimpleResource",nil];
}

@end
