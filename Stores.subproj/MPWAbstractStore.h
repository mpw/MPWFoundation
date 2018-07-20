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


@interface MPWAbstractStore : NSObject<MPWStorage,MPWHierarchicalStorage>

+(instancetype)store;
-objectForReference:aReference;
-(void)setObject:theObject forReference:aReference;
-(void)deleteObjectForReference:aReference;

-referenceForPath:(NSString*)name;

-objectForKeyedSubscript:key;
-(void)setObject:theObject forKeyedSubscript:(id<NSCopying>)key;



-(NSURL*)URLForReference:aReference;

@end

@interface MPWAbstractStore(legacy)

-evaluateIdentifier:anIdentifer withContext:aContext;
-get:(NSString*)uriString parameters:uriParameters;
-get:uri;

@end

