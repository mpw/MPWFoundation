//
//  MPWAbstractStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@protocol MPWReferencing;
@class MPWReference,MPWGenericReference;


@protocol MPWStorage

-objectForReference:( id <MPWReferencing>)aReference;
-(void)setObject:theObject forReference:(id <MPWReferencing>)aReference;
-(void)deleteObjectForReference:(id <MPWReferencing>)aReference;


-(MPWReference*)referenceForPath:(NSString*)path;

@end

@protocol MPWHierarchicalStorage

-(BOOL)isLeafReference:(id <MPWReferencing>)aReference;
-(NSArray<MPWReference*>*)childrenOfReference:(id <MPWReferencing>)aReference;

@end


@interface MPWAbstractStore<__covariant ReferenceType, __covariant ObjectType> : NSObject<MPWStorage,MPWHierarchicalStorage>

+(instancetype)store;
-(ObjectType)objectForReference:(ReferenceType)aReference;
-(void)setObject:(ObjectType)theObject forReference:(ReferenceType)aReference;
-(void)deleteObjectForReference:(ReferenceType)aReference;

-(ReferenceType)referenceForPath:(NSString*)name;

-(ObjectType)objectForKeyedSubscript:key;
-(void)setObject:(ObjectType)theObject forKeyedSubscript:(id<NSCopying>)key;



-(NSURL*)URLForReference:(ReferenceType)aReference;

@end


