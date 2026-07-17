//
//  MPWTableColumn.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 11.03.26.
//

#import "MPWTableColumn.h"
#import "MPWTypeDefinition.h"

@implementation MPWTableColumn
{
    NSString *title;
}

lazyAccessor( NSString*, title, setTitle, key )


-(instancetype)init
{
    self=[super init];
    self.editable=true;
    return self;
}

-(id)objectAtIndex:(NSUInteger)anIndex
{
    [NSException raise:@"unimplemented"
                format:@"Subclass responsibility %@ does not implement %@",NSStringFromClass(self.class),NSStringFromSelector(_cmd)];
    return nil;
}

-(void)replaceObjectAtIndex:(NSUInteger)anIndex withObject:(id)object
{
    [NSException raise:@"unimplemented"
                format:@"Subclass responsibility %@ does not implement %@",NSStringFromClass(self.class),NSStringFromSelector(_cmd)];
}

-(MPWTypeDefinition*)typeAtIndex:(NSUInteger)anIndex
{
    return self.type;
}

-(NSDictionary*)presentationMetadataAtIndex:(NSUInteger)anIndex
{
    return @{};
}

-(BOOL)isEditableAtIndex:(NSUInteger)anIndex
{
    return self.editable;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWTableColumn(testing) 

+(void)testIndexedTypeDefaultsToHomogeneousColumnType
{
    MPWTableColumn *column=[[[MPWTableColumn alloc] init] autorelease];
    MPWTypeDefinition *type=[MPWTypeDefinition descriptorForTypeName:@"Text"];
    column.type=type;
    IDEXPECT([column typeAtIndex:0],type,@"indexed type uses ordinary column type");
    IDEXPECT([column typeAtIndex:100],type,@"ordinary type does not vary by row");
}

+(NSArray*)testSelectors
{
   return @[
			@"testIndexedTypeDefaultsToHomogeneousColumnType",
			];
}

@end
