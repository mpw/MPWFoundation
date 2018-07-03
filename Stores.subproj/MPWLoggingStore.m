//
//  MPWLoggingStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 7/3/18.
//

#import "MPWLoggingStore.h"
#import "MPWGenericReference.h"
#import "AccessorMacros.h"

@interface MPWLoggingStore()

@property (nonatomic, strong) NSObject <Streaming>* log;

@end

@implementation MPWLoggingStore

CONVENIENCEANDINIT( store , WithSource:(NSObject <MPWStorage,MPWHierarchicalStorage>*)aSource loggingTo:(id <Streaming>)log )
{
    self=[super initWithSource:aSource];
    self.log=(NSObject <Streaming>*)log;
    return self;
}

-(void)setObject:anObject forReference:(id<MPWReferencing>)aReference
{
    [super setObject:anObject forReference:aReference];
    [self.log writeObject:aReference];
}

-(void)dealloc
{
    [_log release];
    [super dealloc];
}

@end

@implementation MPWLoggingStore(tests)

+(MPWGenericReference*)ref
{
    return [MPWGenericReference referenceWithPath:@"somePath"];
}

+(void)testWriteIsLogged
{
    NSMutableArray *theLog=[NSMutableArray array];
    MPWLoggingStore *store=[self storeWithSource:nil loggingTo:theLog];
    [store setObject:@"hi" forReference:[self ref]];
    INTEXPECT(theLog.count,1,@"should have logged something");
    
}



+testSelectors
{
    return @[
             @"testWriteIsLogged",
             ];
}

@end
