//
//  MPWObjectTemplate.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 05.06.26.
//

#import "MPWObjectTemplate.h"
#import "MPWTypeDefinition.h"

@interface MPWObjectTemplate()

@property (nonatomic,assign) Class classToInstantiate;
@property (nonatomic,strong) NSDictionary *params;


@end

@implementation MPWObjectTemplate

-(instancetype)initWithClass:(Class)aClass values:(NSDictionary*)params
{
    self=[super init];
    self.classToInstantiate = aClass;
    self.params = params;
    return self;
}

-(id)object
{
    return [[[self.classToInstantiate alloc] initWithDictionary:self.params] autorelease];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWObjectTemplate(testing) 

+(void)testCreateObjectFromTemplate
{
    MPWObjectTemplate *template = [[self alloc] initWithClass:[MPWTypeDefinition class] values:@{
        @"name": @"int",
    }];
    EXPECTNOTNIL( template, @"got a template");
    MPWTypeDefinition *def=[template object];
    EXPECTNOTNIL( def, @"got a object from template");
    IDEXPECT( [def className],@"MPWTypeDefinition", @"it's the right class");
    IDEXPECT( [def name],@"int", @"it's got the right parameter");
}

+(NSArray*)testSelectors
{
   return @[
			@"testCreateObjectFromTemplate",
			];
}

@end
