//
//  MPWLoggingStore.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/3/18.
//

#import <MPWFoundation/MPWMappingStore.h>
#import <MPWFoundation/MPWWriteStream.h>

@interface MPWLoggingStore : MPWMappingStore

+(instancetype)storeWithSource:(NSObject <MPWStorage,MPWHierarchicalStorage>*)aSource loggingTo:(id <Streaming>)log;
-(instancetype)initWithSource:(NSObject <MPWStorage,MPWHierarchicalStorage>*)aSource loggingTo:(id <Streaming>)log;

@property (nonatomic, strong) NSObject <Streaming>* log;

@end

@interface MPWAbstractStore(logging)

-(MPWLoggingStore*)logger;

@end
