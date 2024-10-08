//
//  MPWObjectStore.m
//  MPWFoundation
//
//  A dict store, but first level objects are assumed to be objects
//  with further path traversal.
//
//  Created by Marcel Weiher on 04.10.23.
//

#import "MPWObjectStore.h"

@implementation MPWObjectStore

-(id)at:(id<MPWIdentifying>)aReference
{
    NSString *path=[aReference path];
    if ( [aReference isRoot] || [path isEqual:@"."]) {
        return [self listForNames:[[self dict] allKeys]];
    }
    NSArray *components=[aReference relativePathComponents];
    
    id result=[super at:components[0]];
    if ( components.count > 1 ) {
        components=[components subarrayWithRange:NSMakeRange(1,components.count-1)];
        NSString *remainderRef=[components componentsJoinedByString:@"/"];
        //        MPWIdentifier *remainderRef = [[[[aReference class] alloc] initWithPathComponents:components scheme:[aReference scheme]] autorelease];
//        NSLog(@"initial result: %@",result);
//        NSLog(@"remainder path: '%@'",remainderRef);
        result = [result at:remainderRef];
//        NSLog(@"result: %@",result);
    } else {
    }
    return result;
    
}

-(void)at:(id<MPWIdentifying>)aReference put:theObject
{
//    NSLog(@"ObjectStore at:'%@' put:'%@'",aReference,theObject);
    NSArray *components=[aReference relativePathComponents];
//    components=[components subarrayWithRange:NSMakeRange(0,components.count-1)];
    id <MPWStorage> theStore=self;
    if ( components.count > 1 ) {
        theStore=[super at:components[0]];
//        NSLog(@"got the next level store: %@",theStore);
        components=[components subarrayWithRange:NSMakeRange(1,components.count-1)];
        NSString *remainderRef=[components componentsJoinedByString:@"/"];
        //        MPWIdentifier *remainderRef = [[[[aReference class] alloc] initWithPathComponents:components scheme:[aReference scheme]] autorelease];
//        theStore = [super at:remainderRef];
//        NSLog(@"got initial now doing reminder: '%@' <- '%@'",remainderRef,theObject);
        [theStore at:remainderRef put:theObject];
    } else {
        NSString *componentToWrite=components.lastObject;
        [super at:componentToWrite put:theObject];
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWObjectStore(testing) 

+(void)testObjectAtFirstLevel
{
    MPWObjectStore *store=[self store];
    store[@"hi"]=@"there";
    IDEXPECT( store[@"hi"], @"there", @"top level object");
}

+(void)testReadDeeper
{
    MPWObjectStore *store=[self store];
    NSMutableString *target=[[@"The target" mutableCopy] autorelease];
    MPWFilter *filter=[MPWFilter streamWithTarget:target];
    store[@"hi"]=filter;
    IDEXPECT( store[@"hi"], filter, @"top level object");
    IDEXPECT( store[@"hi/target"], target, @"second level object");
}

+(void)testWriteDeeper
{
    MPWObjectStore *store=[self store];
    NSMutableString *target=[[@"The target" mutableCopy] autorelease];
    MPWFilter *filter=[MPWFilter streamWithTarget:nil];
    store[@"hi"]=filter;
    IDEXPECT( store[@"hi"], filter, @"top level object");
    IDEXPECT( store[@"hi/target"], nil, @"second level object");
    store[@"hi/target"]=target;
    IDEXPECT( filter.target, target, @"did write to second level");
}

+(void)testGetDirectory
{
    MPWObjectStore *store=[self store];
    MPWDirectoryReference *b1=[store at:@"."];
    INTEXPECT( b1.count, 0,@"empty");
    store[@"hi"]=@"there";
    MPWDirectoryReference *b2=[store at:@"."];
    INTEXPECT( b2.count, 1,@"1 entry");
    IDEXPECT( [b2.children[0] path],@"hi",@"entry" );
}

+(NSArray*)testSelectors
{
   return @[
       @"testObjectAtFirstLevel",
       @"testReadDeeper",
       @"testWriteDeeper",
       @"testGetDirectory",
			];
}

@end
