//
//  MPWReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWIdentifier.h>

@implementation MPWIdentifier

-(NSURL *)URL {     return nil;  }
-(BOOL)hasTrailingSlash  {     return NO; }
-(BOOL)isAbsolute  {     return NO; }
-(NSArray*)pathComponents { return nil; }
-(NSString*)name { return self.relativePathComponents.lastObject; }

-(NSArray*)relativePathComponents
{
    NSArray *rawPathComponents=[self pathComponents];
    NSRange r={0,rawPathComponents.count};
    if ( [self isAbsolute] && r.length>0) {
        r.location+=1;
        r.length--;
    }
    if ( [self hasTrailingSlash]  && r.length>0) {
        r.length--;
    }
    return [rawPathComponents subarrayWithRange:r];
}

-asReference
{
    return self;
}

-reference
{
    return self;
}

-(BOOL)isAffectedBy:other
{
    return [self isEqual:other];
}

-(instancetype)referenceByAppendingReference:(id<MPWIdentifying>)other {
    return nil;
}

-(NSString*)relativePath
{
    return [[self relativePathComponents] componentsJoinedByString:@"/"];
}

-(NSString*)urlPath
{
    return [self.pathComponents componentsJoinedByString:@"/"] ?: @"";
}

-(const char*)UTF8String
{
    return [[self path] UTF8String];
}

-(NSComparisonResult)compare:other
{
    return [[self path] compare:[other path]];
}

@synthesize path;

@synthesize schemeName;

@end


@implementation NSString(referencing)

+referenceWithPath:aPath
{
    return aPath;
}

-(NSString*)path
{
    return self;
}

-(BOOL)hasTrailingSlash
{
    return [self hasSuffix:@"/"];
}

-(NSArray<NSString*>*)pathComponents
{
    return [self componentsSeparatedByString:@"/"];
}

-(NSArray<NSString*>*)relativePathComponents
{
    return [self componentsSeparatedByString:@"/"];
}

-(NSString*)schemeName {
    return nil;
}

-(void)setSchemeName:(NSString *)schemeName
{
    
}

-(BOOL)isRoot
{
    return self.length == 0 || [self isEqual:@"/"];
}

-(id<MPWIdentifying>)asReference
{
    return self;
}


- (instancetype)referenceByAppendingReference:(id<MPWIdentifying>)other { 
    return [self stringByAppendingPathComponent:[other path]];
}

-(BOOL)isAffectedBy:other
{
    return [self isEqual:other];
}

-(NSString*)urlPath
{
    return self;
}


@end

#import "DebugMacros.h"

@implementation MPWIdentifier(testing)

+(void)testIsAffectedBySelf
{
    MPWIdentifier *r=[self new];
    EXPECTTRUE([r isAffectedBy:r],@"ref is affected by itself" );
}


+(NSArray*)testSelectors
{
    return @[
        @"testIsAffectedBySelf",
    ];
    
}

@end
