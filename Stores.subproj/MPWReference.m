//
//  MPWReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <MPWReference.h>

@implementation MPWReference

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

@end


@implementation NSString(referencing)

-(NSString*)path
{
    return self;
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

-(id<MPWReferencing>)asReference
{
    return self;
}


- (instancetype)referenceByAppendingReference:(id<MPWReferencing>)other { 
    return [self stringByAppendingPathComponent:[other path]];
}




@end
