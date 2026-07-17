//
//  MPWCompositeTable.m
//  MPWFoundation
//

#import "MPWCompositeTable.h"

@implementation MPWCompositeTable

@synthesize componentTables = _componentTables;

+(instancetype)tableWithComponentTables:(NSArray<MPWTable*>*)tables
{
    return [[[[self class] alloc] initWithComponentTables:tables] autorelease];
}

-(instancetype)initWithComponentTables:(NSArray<MPWTable*>*)tables
{
    self=[super init];
    if (self) { self.componentTables=tables; }
    return self;
}

-(MPWTable*)componentTableAtIndex:(NSUInteger)index
{
    return index < self.componentTables.count ? self.componentTables[index] : nil;
}

-(NSUInteger)count
{
    NSUInteger total=0;
    for (MPWTable *table in self.componentTables) { total += table.count; }
    return total;
}

-(id)objectAtIndex:(NSUInteger)index
{
    for (MPWTable *table in self.componentTables) {
        if (index < table.count) { return [table objectAtIndex:index]; }
        index -= table.count;
    }
    return nil;
}

-(void)rowsDo:(void (^)(NSNumber *))block
{
    for (NSUInteger index=0; index<self.count; index++) { block(@(index)); }
}

-(void)dealloc
{
    [_componentTables release];
    [super dealloc];
}

@end

#import <MPWFoundation/DebugMacros.h>

@implementation MPWCompositeTable (testing)

+(void)testOrdinaryTableIsItsOwnSingleComponent
{
    MPWTable *ordinary=[[[MPWTable alloc] init] autorelease];
    INTEXPECT(ordinary.componentTables.count,1,@"ordinary table has one component");
    IDEXPECT([ordinary componentTableAtIndex:0],ordinary,@"ordinary table returns itself");
    EXPECTNIL([ordinary componentTableAtIndex:1],@"ordinary table has no second component");
}

+(NSArray*)testSelectors
{
    return @[ @"testOrdinaryTableIsItsOwnSingleComponent" ];
}

@end
