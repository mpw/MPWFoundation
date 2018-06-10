//
//  MPWAbstractStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@class MPWReference,MPWGenericReference;


@protocol MPWStorage

-objectForReference:( MPWReference*)aReference;
-(void)setObject:theObject forReference:(MPWReference*)aReference;
-(void)deleteObjectForReference:(MPWReference*)aReference;


-(MPWReference*)referenceForPath:(NSString*)path;
-(MPWReference*)referenceForPathComponents:(NSArray*)path schemeName:(NSString*)schemeName;

@end

@protocol MPWHierarchicalStorage

-(BOOL)isLeafReference:(MPWReference*)aReference;
-(NSArray<MPWReference*>*)childrenOfReference:(MPWReference*)aReference;

@end


@interface MPWAbstractStore<__covariant ReferenceType, __covariant ObjectType> : NSObject<MPWStorage,MPWHierarchicalStorage>

+(instancetype)store;
-(ObjectType)objectForReference:(ReferenceType)aReference;
-(void)setObject:(ObjectType)theObject forReference:(ReferenceType)aReference;
-(void)deleteObjectForReference:(ReferenceType)aReference;

-(ReferenceType)referenceForPath:(NSString*)name;
-(ReferenceType)referenceForPathComponents:(NSArray*)name schemeName:(NSString*)schemeName;

-(ObjectType)objectForKeyedSubscript:key;
-(void)setObject:(ObjectType)theObject forKeyedSubscript:(id<NSCopying>)key;



-(NSURL*)URLForReference:(ReferenceType)aReference;

@end


