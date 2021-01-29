//
//  MPWReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@protocol MPWReferencing <NSCopying>

@property (readonly) NSArray<NSString*> *pathComponents;
@property (readonly) NSArray<NSString*> *relativePathComponents;
@property (nonatomic, strong) NSString *schemeName;
@property (readonly) NSString *path;

-(instancetype)referenceByAppendingReference:(id<MPWReferencing>)other;

@end

@protocol MPWReferenceCreation

-(instancetype)initWithPathComponents:(NSArray*)pathComponents scheme:(NSString*)scheme;
-(instancetype)initWithPath:(NSString*)pathName;
+(instancetype)referenceWithPath:(NSString*)pathName;
-asReference;

@end

@interface MPWReference : NSObject

-(NSURL*)URL;

@property (readonly) NSArray<NSString*> *relativePathComponents;

@end


@interface NSString(referencing) <MPWReferencing>

-(id <MPWReferencing>)asReference;


@end


