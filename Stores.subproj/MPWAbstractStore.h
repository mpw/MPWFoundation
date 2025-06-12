//
//  MPWAbstractStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/21/18.
//

#import <Foundation/Foundation.h>

@protocol MPWIdentifying,Streaming;
@class MPWIdentifier,MPWGenericIdentifier,MPWByteStream,MPWDirectoryReference,MPWReference,MPWPathRelativeStore;


@protocol MPWStorage <NSObject>

-at:(id <MPWIdentifying>)aReference;
-(void)at:(id <MPWIdentifying>)aReference put:theObject;
-(id)at:(id <MPWIdentifying>)aReference post:theObject;
-(void)merge:theObject at:(id <MPWIdentifying>)aReference;
-(void)deleteAt:(id <MPWIdentifying>)aReference;
-(void)mkdirAt:(id <MPWIdentifying>)reference;
-(id <MPWIdentifying>)referenceForPath:(NSString*)path;

@optional
-(NSString*)graphVizName;
-(NSString*)graphViz;
-(void)graphViz:(MPWByteStream*)aStream;
-objectForKeyedSubscript:key;
-(void)setObject:theObject forKeyedSubscript:key;
-(BOOL)hasChildren:(id <MPWIdentifying>)aReference;

-(MPWReference*)bindingForReference:aReference inContext:aContext;
-(id<MPWStorage>)relativeStoreAt:(id <MPWIdentifying>)reference;

@end

@protocol StreamStorage

-(id <Streaming>)writeStreamAt:(id <MPWIdentifying>)aReference;
-(void)at:(id <MPWIdentifying>)aReference readToStream:(id <Streaming>)aStream;

@end

@protocol MPWHierarchicalStorage <MPWStorage>

-(BOOL)hasChildren:(id <MPWIdentifying>)aReference;
-(NSArray<MPWIdentifying>*)childrenOfReference:(id <MPWIdentifying>)aReference;
-(id <MPWIdentifying>)rootRef;
-(MPWReference*)rootBinding;

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
-(MPWDirectoryReference*)listForNames:(NSArray*)nameList;
-(MPWPathRelativeStore*)relativeStoreAt:(id <MPWIdentifying>)reference;


-(void)graphViz:(MPWByteStream*)aStream;
-(NSString*)graphViz;
-(void)reportError:(NSError*)error;

@end

@interface MPWAbstractStore(legacy)

-evaluateIdentifier:anIdentifier withContext:aContext;
-get:(NSString*)uriString parameters:uriParameters;
-get:uri;

@end

