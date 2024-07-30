//
//  MPWGenericIdentifier.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/22/18.
//

#import <MPWFoundation/MPWIdentifier.h>

@interface MPWGenericIdentifier : MPWIdentifier <MPWIdentifying,MPWIdentifierCreation,NSCopying>

-(void)setPath:(NSString*)path;         // legacy/compatibility
-(NSString*)identifierName;
-(BOOL)isRoot;
-(BOOL)hasTrailingSlash;

@end


@interface MPWIdentifierTests : NSObject {}
@end

