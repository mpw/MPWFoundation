//
//  MPWGenericReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/22/18.
//

#import "MPWGenericReference.h"
#import "AccessorMacros.h"

@interface MPWGenericReference()

@property (nonatomic, strong) NSArray *pathComponents;
@property (nonatomic, strong) NSString *scheme;


@end

@implementation MPWGenericReference

-(instancetype)initWithPathComponents:(NSArray*)pathComponents scheme:(NSString*)scheme
{
    self=[super init];
    self.pathComponents=pathComponents;
    self.scheme=scheme;
    return self;
}

CONVENIENCEANDINIT( reference, WithPath:(NSString*)path )
{
    return [self initWithPathComponents:[path componentsSeparatedByString:@"/"] scheme:nil];
}

-(BOOL)isRoot
{
    NSArray *components=self.pathComponents;
    return components.count == 2 && [components[0] length]==0 && [components[1] length]==0;
}

-(BOOL)isAbsolute
{
    NSArray *components=self.pathComponents;
    return components.count >0 && [components[0] length]==0;
}



@end

#import "DebugMacros.h"

@implementation MPWGenericReference(testing)

+(void)testIdentifyRoot
{
    EXPECTTRUE([[MPWGenericReference referenceWithPath:@"/"] isRoot], @"isRoot");
    EXPECTFALSE([[MPWGenericReference referenceWithPath:@"/absolute"] isRoot], @"absolute isRoot");
    EXPECTFALSE([[MPWGenericReference referenceWithPath:@"relative"] isRoot], @"relative isRoot");
}

+(void)testIdentifyAbsolute
{
    EXPECTTRUE([[MPWGenericReference referenceWithPath:@"/"] isAbsolute], @"isRoot");
    EXPECTTRUE([[MPWGenericReference referenceWithPath:@"/absolute"] isAbsolute], @"absolute isRoot");
    EXPECTFALSE([[MPWGenericReference referenceWithPath:@"relative"] isAbsolute], @"relative isRoot");
    EXPECTFALSE([[MPWGenericReference referenceWithPath:@"relative/path"] isAbsolute], @"relative/path isRoot");
}


+testSelectors
{
    return @[
             @"testIdentifyRoot",
             @"testIdentifyAbsolute",
             ];
}

@end
