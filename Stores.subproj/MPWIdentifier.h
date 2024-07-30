//
//  MPWReference.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@protocol MPWIdentifying 

@property (readonly) NSArray<NSString*> *pathComponents;
@property (readonly) NSArray<NSString*> *relativePathComponents;
@property (nonatomic, strong) NSString *schemeName;
@property (readonly) NSString *path;

-(BOOL)isAffectedBy:(id <MPWIdentifying>)other;
-(instancetype)referenceByAppendingReference:(id<MPWIdentifying>)other;

@end

@protocol MPWIdentifierCreation

-(instancetype)initWithPathComponents:(NSArray*)pathComponents scheme:(NSString*)scheme;
-(instancetype)initWithPath:(NSString*)pathName;
+(instancetype)referenceWithPath:(NSString*)pathName;
-asReference;

@end

@interface MPWIdentifier : NSObject <MPWIdentifying>

-(NSURL*)URL;

@property (readonly) NSArray<NSString*> *relativePathComponents;

@end


@interface NSString(referencing) <MPWIdentifying>


@end


