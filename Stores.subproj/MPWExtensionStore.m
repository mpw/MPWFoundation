//
//  MPWExtensionStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 31.03.23.
//

#import "MPWExtensionStore.h"



@implementation MPWExtensionStore

-(id<MPWReferencing>)mapReference:(id<MPWReferencing>)aReference
{
    NSString *r=aReference.path;
    id ref = [[aReference class] referenceWithPath:[r stringByAppendingPathExtension:self.extension]];
    NSLog(@"mapped ref from '%@' to '%@'",aReference,ref);
    return ref;
}

-(id<MPWReferencing>)reverseMapReference:(id<MPWReferencing>)aReference
{
    return [[aReference class] referenceWithPath:[[aReference path] stringByDeletingPathExtension]];
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"<%@:%p: extension: %@ source: %@>",self.class,self,self.extension,self.source];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWExtensionStore(testing) 

+(instancetype)_testStore
{
    NSDictionary *testDict=@{ @"index.html": @"hello world"};
    MPWDictStore *d=[MPWDictStore storeWithDictionary:testDict];
    EXPECTNIL( d[@"index"],@"shouldn't find without the extension")
    MPWExtensionStore *s=[self storeWithSource:d];
    s.extension = @"html";
    return s;
}

+(void)testExtensionAdded
{
    IDEXPECT([self _testStore][@"index"],@"hello world",@"finds by adding extension");
    EXPECTNIL([self _testStore][@"test"],@"key not there");
}

+(void)testExtensionNotStrippedBeforeAdding
{
    EXPECTNIL([self _testStore][@"index.html"],@"extension added twice, so no result");
    EXPECTNIL([self _testStore][@"index.txt"],@"other extension not stripped");
}

+(NSArray*)testSelectors
{
   return @[
       @"testExtensionAdded",
       @"testExtensionNotStrippedBeforeAdding",
			];
}

@end
