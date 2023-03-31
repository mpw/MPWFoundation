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
    return [r stringByAppendingPathExtension:self.extension];
}

-(id<MPWReferencing>)reverseMapReference:(id<MPWReferencing>)aReference
{
    return [[aReference path] stringByDeletingPathExtension];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWExtensionStore(testing) 

+(void)testExtensionAdded
{
    NSDictionary *testDict=@{ @"index.html": @"hello world"};
    MPWDictStore *d=[MPWDictStore storeWithDictionary:testDict];
    EXPECTNIL( d[@"index"],@"shouldn't find without the extension")
    MPWExtensionStore *s=[self storeWithSource:d];
    s.extension = @"html";
    IDEXPECT(s[@"index"],@"hello world",@"finds by adding extension");
    
}

+(NSArray*)testSelectors
{
   return @[
			@"testExtensionAdded",
			];
}

@end
