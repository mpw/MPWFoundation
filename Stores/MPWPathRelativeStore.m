//
//  MPWPathRelativeStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import "MPWPathRelativeStore.h"
#import "MPWGenericReference.h"

@interface MPWPathRelativeStore()

@property (nonatomic, strong) MPWGenericReference* baseReference;

@end

@implementation MPWPathRelativeStore

+(instancetype)storeWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:(MPWGenericReference*)newRef
{
    return [[[self alloc] initWithSource:newSource reference:newRef] autorelease];
}

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:(MPWGenericReference*)newRef
{
    self=[super initWithSource:newSource];
    self.baseReference=newRef;
    return self;
}

-(MPWGenericReference *)mapReference:(MPWGenericReference *)aReference
{
    NSArray *combinedComponents=[[self.baseReference pathComponents] arrayByAddingObjectsFromArray:[aReference relativePathComponents]];
    return [[[MPWGenericReference alloc] initWithPathComponents:combinedComponents scheme:self.baseReference.schemeName] autorelease];
}

@end

#import "DebugMacros.h"
#import "MPWDictStore.h"

@implementation MPWPathRelativeStore(testing)


+(void)testMapPath
{
    MPWGenericReference *prefix=[MPWGenericReference referenceWithPath:@"base"];
    MPWGenericReference *relative=[MPWGenericReference referenceWithPath:@"relative"];
    MPWDictStore *store=[MPWDictStore store];
    MPWMappingStore *mapper=[self storeWithSource:store reference:prefix];
    mapper[(id)relative]=@"world!";
    IDEXPECT( store[@"base/relative"], @"world!", @"store write mapper")
    store[@"base/relative"]=@"new world!";
    IDEXPECT( mapper[(id)relative], @"new world!", @"store read mapper")
}

+testSelectors
{
    return @[
             @"testMapPath"
             ];
    
}


@end
