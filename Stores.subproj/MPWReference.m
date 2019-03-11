//
//  MPWReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import "MPWReference.h"

@implementation MPWReference

-(NSURL *)URL {     return nil;  }
-(BOOL)hasTrailingSlash  {     return NO; }
-(BOOL)isAbsolute  {     return NO; }
-(NSArray*)pathComponents { return nil; }

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

@end

