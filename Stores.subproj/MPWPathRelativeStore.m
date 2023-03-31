//
//  MPWPathRelativeStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/28/18.
//

#import "MPWPathRelativeStore.h"
#import "MPWGenericReference.h"

@interface MPWPathRelativeStore()

@property (nonatomic, strong) id <MPWReferencing> baseReference;

@end

@implementation MPWPathRelativeStore

+(instancetype)storeWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:( id <MPWReferencing>)newRef
{
    return [[[self alloc] initWithSource:newSource reference:newRef] autorelease];
}

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource reference:( id <MPWReferencing>)newRef
{
    self=[super initWithSource:newSource];
    self.baseReference=newRef;
    return self;
}

-(id <MPWReferencing>)mapReference:(MPWGenericReference *)aReference
{
    id mapped = [self.baseReference referenceByAppendingReference:aReference];
//    NSLog(@"map ref from %@ -> %@ via prefix : %@",aReference,mapped,self.baseReference);
    return mapped;
}

-(id <MPWReferencing>)reverseMapReference:(id <MPWReferencing>)aReference
{
    NSString *prefix=self.baseReference.path;
    if ( ![prefix hasSuffix:@"/"]) {
        prefix=[prefix stringByAppendingString:@"/"];
    }
    long len=[prefix length];
    NSString *refPath=aReference.path;
    if ( [refPath hasPrefix:prefix]) {
        refPath = [refPath substringFromIndex:len];
        aReference=[MPWGenericReference referenceWithPath:refPath];
    }
    return aReference;
}

-(NSString*)graphVizName
{
    return [NSString stringWithFormat:@"\"Relative:\\n%@\"",[self.baseReference pathComponents].lastObject];
}


-(void)dealloc
{
    [(id)_baseReference release];
    [super dealloc];
}



@end

#import "DebugMacros.h"
#import "MPWDictStore.h"

@implementation MPWPathRelativeStore(testing)


+(void)testMapPath
{
    MPWGenericReference *prefix=[MPWGenericReference referenceWithPath:@"base"];
    MPWGenericReference *relative=[MPWGenericReference referenceWithPath:@"relative"];
    MPWGenericReference *combined=[MPWGenericReference referenceWithPath:@"base/relative"];
    MPWDictStore *store=[MPWDictStore store];
    MPWMappingStore *mapper=[self storeWithSource:store reference:prefix];
    mapper[(id)relative]=@"world!";
    IDEXPECT( store[combined], @"world!", @"store write mapper")
    store[combined]=@"new world!";
    IDEXPECT( mapper[(id)relative], @"new world!", @"store read mapper")
}

+(void)testBackwardMapRetrievedPaths
{
    MPWGenericReference *prefix=[MPWGenericReference referenceWithPath:@"base"];
    MPWGenericReference *relative=[MPWGenericReference referenceWithPath:@"relative"];
    MPWGenericReference *combined=[MPWGenericReference referenceWithPath:@"base/relative"];
    MPWDictStore *store=[MPWDictStore store];
    MPWMappingStore *mapper=[self storeWithSource:store reference:prefix];
    mapper[(id)relative]=@"world!";
    NSArray<MPWReferencing> *nonmappedRefs = [store childrenOfReference:@""];
    IDEXPECT( [nonmappedRefs.firstObject path], combined.path, @"original, unmapped" );
    NSArray<MPWReferencing> *mappedRefs = [mapper childrenOfReference:@""];
    IDEXPECT( [mappedRefs.firstObject path], relative.path, @"original, remapped" );


}

+testSelectors
{
    return @[
             @"testMapPath",
             @"testBackwardMapRetrievedPaths",
             ];
    
}


@end
