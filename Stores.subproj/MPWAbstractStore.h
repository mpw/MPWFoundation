//
//  MPWAbstractStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@protocol MPWReferencing;
@class MPWReference,MPWGenericReference,MPWByteStream;


@protocol MPWStorage

-objectForReference:(id <MPWReferencing>)aReference;
-(void)setObject:theObject forReference:(id <MPWReferencing>)aReference;
-(void)mergeObject:theObject forReference:(id <MPWReferencing>)aReference;
-(void)deleteObjectForReference:(id <MPWReferencing>)aReference;
-(id <MPWReferencing>)referenceForPath:(NSString*)path;

@optional
-(NSString*)displayName;
-(void)graphViz:(MPWByteStream*)aStream;


@end

@protocol MPWHierarchicalStorage

-(BOOL)isLeafReference:(id <MPWReferencing>)aReference;
-(NSArray<MPWReference*>*)childrenOfReference:(id <MPWReferencing>)aReference;

@end


@interface MPWAbstractStore : NSObject<MPWStorage,MPWHierarchicalStorage>


+(instancetype)stores:(NSArray*)stores;
+(instancetype)store;

-objectForKeyedSubscript:key;
-(void)setObject:theObject forKeyedSubscript:key;

-(NSURL*)URLForReference:aReference;

-(void)setSourceStores:(NSArray <MPWStorage>*)stores;

-(void)graphViz:(MPWByteStream*)aStream;
-(NSString*)graphViz;

@end

@interface MPWAbstractStore(legacy)

-evaluateIdentifier:anIdentifer withContext:aContext;
-get:(NSString*)uriString parameters:uriParameters;
-get:uri;

@end

