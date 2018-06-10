//
//  MPWReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@protocol MPWReferencing

-(instancetype)initWithPathComponents:(NSArray*)pathComponents scheme:(NSString*)scheme;
-(instancetype)initWithPath:(NSString*)pathName;
+(instancetype)referenceWithPath:(NSString*)pathName;


@property (readonly) NSArray *pathComponents;
@property (readonly) NSArray *relativePathComponents;
@property (nonatomic, strong) NSString *schemeName;
@property (readonly) NSString *path;

-(instancetype)referenceByAppendingReference:(id<MPWReferencing>)other;

@end

@interface MPWReference : NSObject

-(NSURL*)URL;

@end


