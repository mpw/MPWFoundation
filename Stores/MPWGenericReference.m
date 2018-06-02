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
@property (nonatomic, strong) NSString *schemeName;


@end

@implementation MPWGenericReference

-(NSArray*)componentsOfPath:(NSString*)path
{
    return [path componentsSeparatedByString:@"/"];
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

-(NSArray*)relativePathComponents
{
    NSArray *rawPathComponents=self.pathComponents;
    NSRange r={0,rawPathComponents.count};
    if ( [self isAbsolute] && r.length>0) {
        r.location+=1;
        r.length--;
    }
    if ( [self hasTrailingSlash]  && r.length>0) {
        r.length--;
    }
    return [rawPathComponents subarrayWithRange:r];
}

-(instancetype)referenceByAppendingReference:(MPWGenericReference*)other
{
    NSArray *compinedPath=[[self pathComponents] arrayByAddingObjectsFromArray:[other relativePathComponents]];
    return [[[[self class] alloc] initWithPathComponents:compinedPath scheme:self.schemeName] autorelease];
}

-(NSString*)stringValue
{
    return [self path];
}


-(void)dealloc
{
    [_pathComponents release];
    [_schemeName release];
    [super dealloc];
}

// FIXME: legacy/compatibility

-(NSString*)path
{
    return [self.pathComponents componentsJoinedByString:@"/"];
}

-(void)setIdentifierName:(NSString*)path
{
    self.pathComponents = [self componentsOfPath:path];
}

-(NSURL *)asURL
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

@implementation MPWGenericReference(testing)

+(void)testIdentifyRoot
{
    EXPECTTRUE([[self referenceWithPath:@"/"] isRoot], @"isRoot");
    EXPECTFALSE([[self referenceWithPath:@"/absolute"] isRoot], @"absolute isRoot");
    EXPECTFALSE([[self referenceWithPath:@"relative"] isRoot], @"relative isRoot");
}

+(void)testIdentifyAbsolute
{
    EXPECTTRUE([[self referenceWithPath:@"/"] isAbsolute], @"isRoot");
    EXPECTTRUE([[self referenceWithPath:@"/absolute"] isAbsolute], @"absolute isRoot");
    EXPECTFALSE([[self referenceWithPath:@"relative"] isAbsolute], @"relative isRoot");
    EXPECTFALSE([[self referenceWithPath:@"relative/path"] isAbsolute], @"relative/path isRoot");
}

+(void)testIdentifyTrailingSlash
{
    EXPECTTRUE([[self referenceWithPath:@"/"] hasTrailingSlash], @"/ hasTrailingSlash");
    EXPECTTRUE([[self referenceWithPath:@"trail/"] hasTrailingSlash], @"trail/ hasTrailingSlash");
    EXPECTFALSE([[self referenceWithPath:@"notrail"] hasTrailingSlash], @"notrail hasTrailingSlash");
    EXPECTFALSE([[self referenceWithPath:@"relative/path"] hasTrailingSlash], @"relative/path hasTrailingSlash");
}

+(void)testReturnsSamePath
{
    IDEXPECT([[self referenceWithPath:@"/"] path], @"/",@"path");
    IDEXPECT([[self referenceWithPath:@"/absolute"] path], @"/absolute",@"path");
    IDEXPECT([[self referenceWithPath:@"relative"] path], @"relative",@"path");
    IDEXPECT([[self referenceWithPath:@"trail/"] path], @"trail/",@"path");
    IDEXPECT([[self referenceWithPath:@"relative/path"] path], @"relative/path",@"path");
}

+(void)testCleanedPath
{
    IDEXPECT([[self referenceWithPath:@"/absolute"] relativePathComponents], @[ @"absolute"] ,@"cleanedPathComponents");
    IDEXPECT([[self referenceWithPath:@"relative"] relativePathComponents], @[@"relative"],@"path");
    IDEXPECT([[self referenceWithPath:@"trail/"] relativePathComponents], @[@"trail"],@"path");
    IDEXPECT([[self referenceWithPath:@"relative/path"] relativePathComponents], (@[@"relative",@"path"]),@"relative");
    IDEXPECT([[self referenceWithPath:@"/"] relativePathComponents], @[] ,@"cleanedPathComponents");
    IDEXPECT([[self referenceWithPath:@""] relativePathComponents], @[] ,@"cleanedPathComponents");
}

+(void)testAsURL
{
    NSString *urlString=@"https://www.metaobject.com";
    NSURL *sourceURL=[NSURL URLWithString:urlString];
    MPWGenericReference *ref=[[self alloc] initWithPathComponents:[@"//www.metaobject.com" componentsSeparatedByString:@"/"] scheme:[sourceURL scheme]];
    IDEXPECT( [ref path], @"//www.metaobject.com", @"path");
    IDEXPECT( [ref asURL], sourceURL, @"urls");
}

+(void)testAppendPath
{
    MPWGenericReference *base=[self referenceWithPath:@"base"];
    MPWGenericReference *relative=[self referenceWithPath:@"relative"];
    MPWGenericReference *composite=[base referenceByAppendingReference:relative];
    IDEXPECT([composite path], @"base/relative", @"simplest composition");
}



+testSelectors
{
    return @[
             @"testIdentifyRoot",
             @"testIdentifyAbsolute",
             @"testIdentifyTrailingSlash",
             @"testAsURL",
             @"testReturnsSamePath",
             @"testCleanedPath",
             @"testAppendPath",
             ];
}

@end
