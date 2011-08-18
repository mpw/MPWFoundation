//
//  NSBundleConveniences.m
//  MPWFoundation
//
//  Created by marcel on Fri Aug 31 2001.
/*  
    Copyright (c) 2001-2011 by Marcel Weiher.  All rights reserved.


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
//

#import "NSBundleConveniences.h"
#import "NSStringAdditions.h"

@implementation NSBundle(Conveniences)

-(NSData*)resourceWithName:(NSString*)aName type:(NSString*)aType 
{
	NSString *path = [self pathForResource:aName ofType:aType];
	NSData *data;
    data =  [NSData dataWithContentsOfMappedFile:path];
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
    id expectedResource = @"This is a simple resource";
    id resource = [[self resourceWithName:@"ResourceTest" type:@""] stringValue];
    NSAssert2( [resource isEqual:expectedResource], @"Got resource '%@', expected '%@'",
        resource,expectedResource);
}

+(NSArray*)testSelectors
{
    return [NSArray arrayWithObjects:@"testSimpleResource",nil];
}

@end
