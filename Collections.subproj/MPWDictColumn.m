//
//  MPWDictColumn.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 23.03.26.
//

#import "MPWDictColumn.h"

@interface MPWDictColumn ()

@property (nonatomic, weak) NSArray *objects;
@property (nonatomic, weak) NSString *key;

@end

@implementation MPWDictColumn

CONVENIENCEANDINIT(column, WithArray:(NSArray*)anArray key:(NSString*)newKey)
{
    self=[super init];
    self.objects=anArray;
    self.key=newKey;
    return self;
}
                

-(id)objectAtIndex:(NSUInteger)anIndex
{
    return _objects[anIndex][_key];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWDictColumn(testing)




+(void)testBasicAccess
{
    NSArray *names = @[ @{ @"first": @"Marcel", @"last": @"Weiher" }, @{@"first": @"John", @"last": @"Doe" }];
    MPWDictColumn *first=[MPWDictColumn columnWithArray:names key:@"first"];
    IDEXPECT( [first objectAtIndex:0], @"Marcel", @"first name of first row");
    IDEXPECT( [first objectAtIndex:1], @"John", @"first name of second row");
    MPWDictColumn *last=[MPWDictColumn columnWithArray:names key:@"last"];
    IDEXPECT( [last objectAtIndex:0], @"Weiher", @"last name of first row");
    IDEXPECT( [last objectAtIndex:1], @"Doe", @"last name of second row");
}

+(NSArray*)testSelectors
{
   return @[
			@"testBasicAccess",
			];
}

@end
