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

+(void)testIdentifyTrailingSlash
{
    EXPECTTRUE([[MPWGenericReference referenceWithPath:@"/"] hasTrailingSlash], @"/ hasTrailingSlash");
    EXPECTTRUE([[MPWGenericReference referenceWithPath:@"trail/"] hasTrailingSlash], @"trail/ hasTrailingSlash");
    EXPECTFALSE([[MPWGenericReference referenceWithPath:@"notrail"] hasTrailingSlash], @"notrail hasTrailingSlash");
    EXPECTFALSE([[MPWGenericReference referenceWithPath:@"relative/path"] hasTrailingSlash], @"relative/path hasTrailingSlash");
}

+(void)testReturnsSamePath
{
    IDEXPECT([[MPWGenericReference referenceWithPath:@"/"] path], @"/",@"path");
    IDEXPECT([[MPWGenericReference referenceWithPath:@"/absolute"] path], @"/absolute",@"path");
    IDEXPECT([[MPWGenericReference referenceWithPath:@"relative"] path], @"relative",@"path");
    IDEXPECT([[MPWGenericReference referenceWithPath:@"trail/"] path], @"trail/",@"path");
    IDEXPECT([[MPWGenericReference referenceWithPath:@"relative/path"] path], @"relative/path",@"path");
}

+(void)testCleanedPath
{
    IDEXPECT([[MPWGenericReference referenceWithPath:@"/absolute"] relativePathComponents], @[ @"absolute"] ,@"cleanedPathComponents");
    IDEXPECT([[MPWGenericReference referenceWithPath:@"relative"] relativePathComponents], @[@"relative"],@"path");
    IDEXPECT([[MPWGenericReference referenceWithPath:@"trail/"] relativePathComponents], @[@"trail"],@"path");
    IDEXPECT([[MPWGenericReference referenceWithPath:@"relative/path"] relativePathComponents], (@[@"relative",@"path"]),@"relative");
    IDEXPECT([[MPWGenericReference referenceWithPath:@"/"] relativePathComponents], @[] ,@"cleanedPathComponents");
}

+(void)testAsURL
{
    NSString *urlString=@"https://www.metaobject.com";
    NSURL *sourceURL=[NSURL URLWithString:urlString];
    MPWGenericReference *ref=[[self alloc] initWithPathComponents:[@"//www.metaobject.com" componentsSeparatedByString:@"/"] scheme:[sourceURL scheme]];
    IDEXPECT( [ref path], @"//www.metaobject.com", @"path");
    IDEXPECT( [ref asURL], sourceURL, @"urls");
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
             ];
}

@end
