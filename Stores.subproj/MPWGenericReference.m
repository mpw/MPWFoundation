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


@end

@implementation MPWGenericReference

@synthesize schemeName;

-(NSArray*)componentsOfPath:(NSString*)path
{
    NSArray *components = [path componentsSeparatedByString:@"/"];
    if ( components.count == 1 && [components.firstObject length] == 0) {
        components=@[];
    }
    return components;
}

-(instancetype)initWithPathComponents:(NSArray*)pathComponents scheme:(NSString*)scheme
{
    self=[super init];
    self.pathComponents=pathComponents;
    self.schemeName=scheme;
    return self;
}

CONVENIENCEANDINIT( reference, WithPath:(NSString*)path )
{
    return [self initWithPathComponents:[self componentsOfPath:path] scheme:nil];
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

-(BOOL)hasTrailingSlash
{
    return [self.pathComponents.lastObject length]==0;
}

-(instancetype)referenceByAppendingReference:(MPWGenericReference*)other
{
    NSArray *compinedPath=[[self pathComponents] arrayByAddingObjectsFromArray:[other relativePathComponents]];
    return [[[[self class] alloc] initWithPathComponents:compinedPath scheme:self.schemeName] autorelease];
}

-(NSArray*)relativePathComponents
{
    return [super relativePathComponents];      // shut up the compiler
}

-(NSString*)stringValue
{
    return [self path];
}


-(void)dealloc
{
    [_pathComponents release];
    [schemeName release];
    [super dealloc];
}

// FIXME: legacy/compatibility

-(NSString*)path
{
    return [self.pathComponents componentsJoinedByString:@"/"];
}

-(void)setPath:(NSString*)path
{
    self.pathComponents = [self componentsOfPath:path];
}

-(NSURL *)URL
{
    NSMutableString *s=[NSMutableString string];
    if ( [self schemeName]) {
        [s appendString:[self schemeName]];
        [s appendString:@":"];
    }
    [s appendString:[self path]];
    return [NSURL URLWithString:s];
}

-(NSString*)name
{
    return [self path];
}

-(NSString*)identifierName
{
    return [self path];
}


@end

#import "DebugMacros.h"


@implementation MPWReferenceTests


+classUnderTest
{
    return [MPWGenericReference class];
}

+(void)testIdentifyRoot
{
    EXPECTTRUE([[[self classUnderTest] referenceWithPath:@"/"] isRoot], @"isRoot");
    EXPECTFALSE([[[self classUnderTest] referenceWithPath:@"/absolute"] isRoot], @"absolute isRoot");
    EXPECTFALSE([[[self classUnderTest] referenceWithPath:@"relative"] isRoot], @"relative isRoot");
}

+(void)testIdentifyAbsolute
{
    EXPECTTRUE([[[self classUnderTest] referenceWithPath:@"/"] isAbsolute], @"isRoot");
    EXPECTFALSE([[[self classUnderTest] referenceWithPath:@""] isAbsolute], @"isRoot");
    EXPECTTRUE([[[self classUnderTest] referenceWithPath:@"/absolute"] isAbsolute], @"absolute isRoot");
    EXPECTFALSE([[[self classUnderTest] referenceWithPath:@"relative"] isAbsolute], @"relative isRoot");
    EXPECTFALSE([[[self classUnderTest] referenceWithPath:@"relative/path"] isAbsolute], @"relative/path isRoot");
}

+(void)testIdentifyTrailingSlash
{
    EXPECTTRUE([[[self classUnderTest] referenceWithPath:@"/"] hasTrailingSlash], @"/ hasTrailingSlash");
    EXPECTTRUE([[[self classUnderTest] referenceWithPath:@"trail/"] hasTrailingSlash], @"trail/ hasTrailingSlash");
    EXPECTFALSE([[[self classUnderTest] referenceWithPath:@"notrail"] hasTrailingSlash], @"notrail hasTrailingSlash");
    EXPECTFALSE([[[self classUnderTest] referenceWithPath:@"relative/path"] hasTrailingSlash], @"relative/path hasTrailingSlash");
}

+(void)testReturnsSamePath
{
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"/"] path], @"/",@"path");
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"/absolute"] path], @"/absolute",@"path");
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"relative"] path], @"relative",@"path");
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"trail/"] path], @"trail/",@"path");
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"relative/path"] path], @"relative/path",@"path");
}

+(void)testCleanedPath
{
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"/absolute"] relativePathComponents], @[ @"absolute"] ,@"cleanedPathComponents");
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"relative"] relativePathComponents], @[@"relative"],@"path");
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"trail/"] relativePathComponents], @[@"trail"],@"path");
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"relative/path"] relativePathComponents], (@[@"relative",@"path"]),@"relative");
    IDEXPECT([[[self classUnderTest] referenceWithPath:@"/"] relativePathComponents], @[] ,@"cleanedPathComponents");
    IDEXPECT([[[self classUnderTest] referenceWithPath:@""] relativePathComponents], @[] ,@"cleanedPathComponents");
}

+(void)testURL {}

+(void)testAppendPath
{
    MPWGenericReference *base=[[self classUnderTest] referenceWithPath:@"base"];
    MPWGenericReference *relative=[[self classUnderTest] referenceWithPath:@"relative"];
    MPWGenericReference *composite=[base referenceByAppendingReference:relative];
    IDEXPECT([composite path], @"base/relative", @"simplest composition");
}



+testSelectors
{
    return @[
             @"testIdentifyRoot",
             @"testIdentifyAbsolute",
             @"testIdentifyTrailingSlash",
             @"testURL",
             @"testReturnsSamePath",
             @"testCleanedPath",
             @"testAppendPath",
             ];
}

@end
