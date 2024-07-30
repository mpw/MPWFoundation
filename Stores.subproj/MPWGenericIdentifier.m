//
//  MPWGenericReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/22/18.
//

#import "MPWGenericIdentifier.h"
#import <AccessorMacros.h>

@interface MPWGenericIdentifier()

@property (nonatomic, strong) NSArray *myPathComponents;


@end

@implementation MPWGenericIdentifier

@synthesize schemeName;

-copyWithZone:(NSZone*)azone
{
    return [self retain];
}

-(BOOL)hasChildren
{
    return NO;
}

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
    self.myPathComponents=pathComponents;
    self.schemeName=scheme;
    return self;
}

CONVENIENCEANDINIT( reference, WithPath:(NSString*)path )
{
    return [self initWithPathComponents:[self componentsOfPath:path] scheme:nil];
}

- (id)asReference {
    return self;
}

-(NSArray*)pathComponents
{
    return _myPathComponents;
}

-(BOOL)isRoot
{
    NSArray *components=self.pathComponents;
    return components.count == 0 || (components.count == 2 && [components[0] length]==0 && [components[1] length]==0);
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

-fancyPath
{
    return [self path];
}

-fileSize {
    return @(0);
}

-(instancetype)referenceByAppendingReference:(MPWGenericIdentifier*)other
{
    NSArray *compinedPath=[[self pathComponents] arrayByAddingObjectsFromArray:[other relativePathComponents]];
    return [[[[self class] alloc] initWithPathComponents:compinedPath scheme:self.schemeName] autorelease];
}

-(instancetype)referenceByAppendingPath:(NSString*)path
{
    MPWGenericIdentifier *otherRef=[[[[self class] alloc] initWithPath:path] autorelease];
    return [self referenceByAppendingReference:otherRef];
}

-(NSArray*)referencesByAppendingPaths:(NSArray*)paths
{
    NSMutableArray *refs=[NSMutableArray array];
    for ( NSString *path in paths ) {
        [refs addObject:[self referenceByAppendingPath:path]];
    }
    return refs;
}

-(NSUInteger)length
{
    NSLog(@"-[MPWGenericReference length] on %@ -> %@",self,[NSThread callStackSymbols]);
    return [[self name] length];
}

-(int)characterAtIndex:(NSUInteger)theIndex
{
    NSLog(@"-[MPWGenericReference characterAtIndex:%ld] on %@ -> %@",theIndex,self,[NSThread callStackSymbols]);
    return [[self name] characterAtIndex:theIndex];
}


-(NSArray*)relativePathComponents
{
    return [super relativePathComponents];      // shut up the compiler
}

-(NSString*)stringValue
{
    return [self path];
}

-(BOOL)isEqual:other
{
    NSArray *components = [self pathComponents];
    if ( components ) {
        return [components isEqual:[other pathComponents]];
    } else {
        return components == [other pathComponents];
    }
}

-(NSUInteger)hash
{
    return [[self path] hash];
}



-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: %@>",[self class],self,[self path]];
}

-(void)dealloc
{
    [_myPathComponents release];
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
    self.myPathComponents = [self componentsOfPath:path];
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


@implementation MPWIdentifierTests


+classUnderTest
{
    return [MPWGenericIdentifier class];
}

+ref:(NSString*)path
{
    return [[self classUnderTest] referenceWithPath:path];
}

+(void)testIdentifyRoot
{
    EXPECTTRUE([[self ref:@"/"] isRoot], @"isRoot");
    EXPECTFALSE([[self ref:@"/absolute"] isRoot], @"absolute isRoot");
    EXPECTFALSE([[self ref:@"relative"] isRoot], @"relative isRoot");
}

+(void)testIdentifyAbsolute
{
    EXPECTTRUE([[self ref:@"/"] isAbsolute], @"isRoot");
    EXPECTFALSE([[self ref:@""] isAbsolute], @"isRoot");
    EXPECTTRUE([[self ref:@"/absolute"] isAbsolute], @"absolute isRoot");
    EXPECTFALSE([[self ref:@"relative"] isAbsolute], @"relative isRoot");
    EXPECTFALSE([[self ref:@"relative/path"] isAbsolute], @"relative/path isRoot");
}

+(void)testIdentifyTrailingSlash
{
    EXPECTTRUE([[self ref:@"/"] hasTrailingSlash], @"/ hasTrailingSlash");
    EXPECTTRUE([[self ref:@"trail/"] hasTrailingSlash], @"trail/ hasTrailingSlash");
    EXPECTFALSE([[self ref:@"notrail"] hasTrailingSlash], @"notrail hasTrailingSlash");
    EXPECTFALSE([[self ref:@"relative/path"] hasTrailingSlash], @"relative/path hasTrailingSlash");
}

+(void)testReturnsSamePath
{
    IDEXPECT([[self ref:@"/"] path], @"/",@"path");
    IDEXPECT([[self ref:@"/absolute"] path], @"/absolute",@"path");
    IDEXPECT([[self ref:@"relative"] path], @"relative",@"path");
    IDEXPECT([[self ref:@"trail/"] path], @"trail/",@"path");
    IDEXPECT([[self ref:@"relative/path"] path], @"relative/path",@"path");
}

+(void)testCleanedPath
{
    IDEXPECT([[self ref:@"/absolute"] relativePathComponents], @[ @"absolute"] ,@"cleanedPathComponents");
    IDEXPECT([[self ref:@"relative"] relativePathComponents], @[@"relative"],@"path");
    IDEXPECT([[self ref:@"trail/"] relativePathComponents], @[@"trail"],@"path");
    IDEXPECT([[self ref:@"relative/path"] relativePathComponents], (@[@"relative",@"path"]),@"relative");
    IDEXPECT([[self ref:@"/"] relativePathComponents], @[] ,@"cleanedPathComponents");
    IDEXPECT([[self ref:@""] relativePathComponents], @[] ,@"cleanedPathComponents");
}

+(void)testPathWithSpaces
{
    id ref = [self ref:@"single space"];
    NSArray* components = [ref relativePathComponents];
    NSString *expected = @"single space";
    NSString* result = [[expected stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]] stringByRemovingPercentEncoding];
    NSLog(@"string escaping and unescaping result: '%@' class: %@",result,[result class]);
    BOOL same = [expected isEqualToString:result];
    INTEXPECT( components.count, 1,@"on path element");
    EXPECTTRUE(same, @"string are the same");
    
    IDEXPECT(result , expected ,@"single space");
}

+(void)testURL {}

+(void)testAppendPath
{
    MPWGenericIdentifier *base=[self ref:@"base"];
    MPWGenericIdentifier *relative=[self ref:@"relative"];
    MPWGenericIdentifier *composite=[base referenceByAppendingReference:relative];
    IDEXPECT([composite path], @"base/relative", @"simplest composition");
}

+(void)testAppendPathWithSpaces
{
    MPWGenericIdentifier *base=[self ref:@"base with space"];
    MPWGenericIdentifier *relative=[self ref:@"relative with space"];
    MPWGenericIdentifier *composite=[base referenceByAppendingReference:relative];
    IDEXPECT([composite path], @"base with space/relative with space", @"simplest composition");
}

+(void)testEquality
{
    EXPECTTRUE( [[self ref:@"/"] isEqual: [self ref:@"/"]],@"root is equal to self");
}

+(void)testAffectedBy
{
    EXPECTTRUE( [[self ref:@"/"] isAffectedBy: [self ref:@"/"]],@"root affected by self");
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
             @"testPathWithSpaces",
             @"testAppendPath",
             @"testAppendPathWithSpaces",
             @"testEquality",
             @"testAffectedBy",
             ];
}

@end


