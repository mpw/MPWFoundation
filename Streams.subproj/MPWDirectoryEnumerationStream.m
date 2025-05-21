//
//  MPWDirectoryEnumerationStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 14.05.25.
//

#import "MPWDirectoryEnumerationStream.h"

@interface MPWDirectoryEnumerationStream()

@property (nonatomic, strong) NSDirectoryEnumerator *direnum;

@end

@implementation MPWDirectoryEnumerationStream

-(instancetype)initWithDirectoryEnumerator:anEnumerator
{
    self=[super init];
    self.direnum = anEnumerator;
    return self;
}

-(instancetype)initWithPath:(NSString*)aPath
{
    return [self initWithDirectoryEnumerator:[[NSFileManager defaultManager] enumeratorAtPath:aPath]];
}

-(id)nextObject
{
    return self.direnum.nextObject;
}

-(void)dealloc
{
    [_direnum release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWDirectoryEnumerationStream(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
