//
//  MPWGenericReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/22/18.
//

#import "MPWReference.h"

@interface MPWGenericReference : MPWReference

-(instancetype)initWithPathComponents:(NSArray*)pathComponents scheme:(NSString*)scheme;
-(instancetype)initWithPath:(NSString*)pathName;
+(instancetype)referenceWithPath:(NSString*)pathName;


@property (readonly) NSArray *pathComponents;
@property (readonly) NSArray *relativePathComponents;
@property (readonly) NSString *schemeName;
@property (readonly) NSString *path;


@end
