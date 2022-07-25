//
//  MPWPlistStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 10.11.21.
//

#import "MPWPlistStore.h"

@implementation MPWPlistStore


-(id)at:(id<MPWReferencing>)aReference
{
    NSLog(@"at: %@",aReference);
    id tempResult=self.dict;
        NSArray *pathComponents=[aReference relativePathComponents];
        for (NSString *step in pathComponents) {
            if ( step.length > 0) {
                if ( ![step isEqualToString:@"."]) {
                    tempResult = [tempResult at:step];
                }
            }
//            NSLog(@"after step: %@",tempResult);
        }
        NSLog(@"return: %@",[tempResult class]);
        return tempResult;
}

-(NSArray<MPWReferencing> *)childrenOfReference:(id<MPWReferencing>)aReference
{
    NSLog(@"childrenOfReference: %@",aReference);
    id base =  [self at:aReference];
    NSString *path=[aReference path];
    path = [path hasPrefix:@"/"] ? [path substringFromIndex:1] : path;
    NSArray<MPWReferencing> *retval=nil;
    if ( [base isKindOfClass:[NSDictionary class]] ) {
//        return [[path collect] stringByAppendingPathComponent:[[base allKeys] each]];
        retval = (NSArray<MPWReferencing>*)[base allKeys];
    } else {
        NSMutableArray<MPWReferencing> * _Nonnull result=(NSMutableArray<MPWReferencing> * _Nonnull)[NSMutableArray arrayWithCapacity:[base count]+1];
        for ( long i=0,max=[base count];i<max;i++) {
            [result addObject:[NSString stringWithFormat:@"%ld",i]];
        }
        retval = result;
    }
    NSLog(@"children: %@",retval);
    return retval;
}

-(BOOL)hasChildren:(id<MPWReferencing>)aReference
{
    id element = [self at:aReference];
    BOOL hasChildren = [element isKindOfClass:[NSArray class]] || [element isKindOfClass:[NSDictionary class]];
    NSLog(@"%@ hasChildren: %d",aReference,hasChildren);
    return hasChildren;
}


@end


@implementation MPWPlistStore(testing)

+(void)testCanReturnNestedElement
{
    NSMutableDictionary *d=[[@{
        @"base" : @{ @"level1" : @1 }
    }  mutableCopy] autorelease];
    MPWPlistStore *s=[self storeWithDictionary:d];
    NSNumber *one=s[@"base/level1"];
    IDEXPECT(one, @1, @"value at nested path");
}

+(void)testCanReturnNestedArrayElements
{
    NSMutableDictionary *d=[[@{
        @"base" : @[ @1, @2, @3 ]
    }  mutableCopy] autorelease];
    MPWPlistStore *s=[self storeWithDictionary:d];
    NSNumber *one=s[@"base/1"];
    IDEXPECT(one, @2, @"value at nested path");
}

+(void)testHasChildren
{
    NSMutableDictionary *d=[[@{
        @"base" : @[ @1, @2, @3 ]
    }  mutableCopy] autorelease];
    MPWPlistStore *s=[self storeWithDictionary:d];
    EXPECTTRUE([s hasChildren:@"/"],@"root has children");
    EXPECTTRUE([s hasChildren:@"base"],@"base has children");
    EXPECTFALSE([s hasChildren:@"base/0"],@"base/0 has children");
}

+(void)testChildrenOf
{
    NSMutableDictionary *d=[[@{
        @"base" : @[ @1, @2, @3 ],
        @"second" : @{ @"a": @"hello" , @"b": @"world"}
    } mutableCopy] autorelease];
    MPWPlistStore *s=[self storeWithDictionary:d];
    id rootChildren=[s childrenOfReference:@"/"];
    IDEXPECT( rootChildren, (@[@"base", @"second"]),@"children of root");
    id baseChildren=[s childrenOfReference:@"base"];
//    IDEXPECT( baseChildren, (@[ @"base/0", @"base/1", @"base/2"]),@"children of base");
    IDEXPECT( baseChildren, (@[ @"0", @"1", @"2"]),@"children of base");
    id baseChildrenWithRoot=[s childrenOfReference:@"/base"];
//    IDEXPECT( baseChildrenWithRoot, (@[ @"base/0", @"base/1", @"base/2"]),@"children of base");
    IDEXPECT( baseChildrenWithRoot, (@[ @"0", @"1", @"2"]),@"children of base");
}

+(NSArray*)testSelectors
{
    return @[
        @"testCanReturnNestedElement",
        @"testCanReturnNestedArrayElements",
        @"testHasChildren",
        @"testChildrenOf",
    ];
}

@end
