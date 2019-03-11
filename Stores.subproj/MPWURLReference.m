//
//  MPWURLReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 6/10/18.
//

#import "MPWURLReference.h"

@interface MPWURLReference()

@property (nonatomic,strong) NSString *scheme,*host;
@property (nonatomic,strong) NSArray *pathComponents;



@end


@implementation MPWURLReference

static NSURL *url( NSString *scheme, NSString* host1, NSString *path1, NSString *path2 ) {
    NSMutableString *s=[NSMutableString string];
    if ( scheme ) {
        [s appendFormat:@"%@:",scheme];
    }
    if ( host1 ) {
        [s appendFormat:@"//%@",host1];
    }
    if ( path1 ) {
        [s appendString:path1];
    }
    if ( path2 ) {
        if ( !([s hasSuffix:@"/"] || [path2 hasPrefix:@"/"])) {
            [s appendString:@"/"];
        }
        [s appendString:path2];
    }
//    NSLog(@"string to feed URL with: %@",s);
    return [NSURL URLWithString:s];
}


CONVENIENCEANDINIT( reference, WithURL:(NSURL*)newURL )
{
    return [self initWithPathComponents:[newURL.path componentsSeparatedByString:@"/"] host:newURL.host scheme:newURL.scheme];
}


CONVENIENCEANDINIT( reference, WithPath:(NSString*)pathName )
{
    return [self initWithPathComponents:[pathName componentsSeparatedByString:@"/"] host:nil scheme:nil];
}

-(instancetype)initWithPathComponents:(NSArray *)pathComponents host:(NSString*)host scheme:(NSString *)scheme
{
    self=[super init];
    self.pathComponents=pathComponents;
    self.scheme=scheme;
    self.host=host;
    return self;
}

-(NSString *)path
{
    return [self.pathComponents componentsJoinedByString:@"/"] ?: @"";

}

-(NSURL *)URL
{
    return url(self.scheme, self.host, self.path , nil);
}

-(NSArray*)relativePathComponents
{
    NSArray *components = [super relativePathComponents];
    if ( components.count==1 && [components.firstObject isEqualToString:@""]) {
        components=@[];
    }
    return components;
}

- (instancetype)referenceByAppendingReference:(id<MPWReferencing>)other
{
    return  [[self class] referenceWithURL:url( [self schemeName], [self host],[self path], [other path])];
}
            

-(NSString*)schemeName
{
    return self.URL.scheme;
}

-(void)setSchemeName:(NSString *)scheme
{
    self.scheme = scheme;
}

-(BOOL)isRoot
{
    NSString *path=[self path];
    return [path isEqualToString:@"/"];
}

-(BOOL)isAbsolute
{
    NSString *path=[self path];
    return [path hasPrefix:@"/"];
}

-(BOOL)hasTrailingSlash
{
    return [[self path] hasSuffix:@"/"];
}

-(BOOL)isEqual:(MPWURLReference*)other
{
    return
    _idsAreEqual(self.pathComponents , other.pathComponents) &&
    _idsAreEqual(self.scheme , other.scheme) &&
    _idsAreEqual(self.host , other.host);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: URL: %@>",[self class],self,[[self URL] description]];
}


-(void)dealloc
{
    [_scheme release];
    [_host release];
    [_pathComponents release];
    [super dealloc];
}

@end

#import "MPWGenericReference.h"

@interface MPWURLReferenceTests : MPWReferenceTests {}
@end

@implementation MPWURLReferenceTests

+classUnderTest
{
    return [MPWURLReference class];
}

+(void)testURL
{
    NSString *urlString=@"http://www.metaobject.com/";
    NSURL *sourceURL=[NSURL URLWithString:urlString];
    MPWURLReference *ref=[[[[self classUnderTest] alloc] initWithURL:sourceURL] autorelease];
    IDEXPECT( [[ref URL] host], @"www.metaobject.com", @"host ");
    IDEXPECT( [ref URL], sourceURL, @"urls");

    NSString *fileURLString=@"file:/hi";
    NSURL *fileURL=[NSURL URLWithString:fileURLString];
    MPWURLReference *fileRef=[[[[self classUnderTest] alloc] initWithURL:fileURL] autorelease];
    IDEXPECT( [fileRef path], @"/hi", @"path");
    IDEXPECT( [fileRef URL], fileURL, @"urls");

}


@end

