//
//  MPWAbstractStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@protocol MPWReferencing,Streaming;
@class MPWReference,MPWGenericReference,MPWByteStream,MPWDirectoryBinding,MPWBinding,MPWPathRelativeStore;


@protocol MPWStorage <NSObject>

-at:(id <MPWReferencing>)aReference;
-(void)at:(id <MPWReferencing>)aReference put:theObject;
-(void)merge:theObject at:(id <MPWReferencing>)aReference;
-(void)deleteAt:(id <MPWReferencing>)aReference;
-(void)mkdirAt:(id <MPWReferencing>)reference;
-(id <MPWReferencing>)referenceForPath:(NSString*)path;

@optional
-(NSString*)graphVizName;
-(NSString*)graphViz;
-(void)graphViz:(MPWByteStream*)aStream;
-objectForKeyedSubscript:key;
-(void)setObject:theObject forKeyedSubscript:key;
-(BOOL)hasChildren:(id <MPWReferencing>)aReference;

-(MPWBinding*)bindingForReference:aReference inContext:aContext;
-(id<MPWStorage>)relativeStoreAt:(id <MPWReferencing>)reference;

@end

@protocol StreamStorage

-(id <Streaming>)writeStreamAt:(id <MPWReferencing>)aReference;
-(void)at:(id <MPWReferencing>)aReference readToStream:(id <Streaming>)aStream;

@end

@protocol MPWHierarchicalStorage <MPWStorage>

-(BOOL)hasChildren:(id <MPWReferencing>)aReference;
-(NSArray<MPWReferencing>*)childrenOfReference:(id <MPWReferencing>)aReference;

@end


@interface MPWAbstractStore : NSObject<MPWStorage,MPWHierarchicalStorage,StreamStorage>
{
}

@property (nonatomic, retain)  NSObject <Streaming> *errors;
@property (nonatomic, retain)  NSString *name;

+(instancetype)store;
+(NSArray*)storesWithDescription:(NSArray*)storeDescriptions;
+(instancetype)stores:(NSArray*)storeDescriptions;

-objectForKeyedSubscript:key;
-(void)setObject:theObject forKeyedSubscript:key;

-(NSURL*)URLForReference:aReference;

-(void)setSourceStores:(NSArray <MPWStorage>*)stores;
-(void)setStoreDict:(NSDictionary*)storeDict;
-(MPWDirectoryBinding*)listForNames:(NSArray*)nameList;
-(MPWPathRelativeStore*)relativeStoreAt:(id <MPWReferencing>)reference;


-(void)graphViz:(MPWByteStream*)aStream;
-(NSString*)graphViz;
-(void)reportError:(NSError*)error;

@end

@interface MPWAbstractStore(legacy)

-evaluateIdentifier:anIdentifier withContext:aContext;
-get:(NSString*)uriString parameters:uriParameters;
-get:uri;

@end

