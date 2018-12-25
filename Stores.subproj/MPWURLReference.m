//
//  MPWURLReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 6/10/18.
//

#import "MPWURLReference.h"

@interface MPWURLReference()

@property (nonatomic, strong) NSURL *URL;

@end


@implementation MPWURLReference

static NSURL *url( NSString *scheme, NSString *path1, NSString *path2 ) {
    NSMutableString *s=[NSMutableString string];
    if ( scheme ) {
        [s appendFormat:@"%@://",scheme];
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
    return [NSURL URLWithString:s];
}


CONVENIENCEANDINIT( reference, WithURL:(NSURL*)newURL )
{
    self=[super init];
    self.URL = newURL;
    return self;
}


CONVENIENCEANDINIT( reference, WithPath:(NSString*)pathName )
{
    return [self initWithURL:url( nil,pathName,nil )];
}

-(instancetype)initWithPathComponents:(NSArray *)pathComponents scheme:(NSString *)scheme
{
    return [self initWithURL:url( scheme,[pathComponents componentsJoinedByString:@"/"],nil )];
}

-(NSString *)path
{
    return self.URL.relativeString;
}

-(NSArray *)pathComponents
{
    NSArray *pathComponents = [self.path componentsSeparatedByString:@"/"];
    if ( pathComponents.count == 1 && [pathComponents.firstObject length]==0) {
        pathComponents=@[];
    }
    return pathComponents;
}

-(NSArray*)relativePathComponents
{
    return [super relativePathComponents];
}

- (instancetype)referenceByAppendingReference:(id<MPWReferencing>)other
{
    return  [[self class] referenceWithURL:url( [self schemeName], [self path], [other path])];
}
            

-(NSString*)schemeName
{
    return self.URL.scheme;
}

-(void)setSchemeName:(NSString *)scheme
{
    self.URL = url( scheme, [self path],nil);
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

-(BOOL)isEqual:other
{
    return [[self URL] isEqual:[other URL]];
}

-(void)dealloc
{
    [_URL release];
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
    NSString *urlString=@"http://www.metaobject.com";
    NSURL *sourceURL=[NSURL URLWithString:urlString];
    MPWGenericReference *ref=[[[[self classUnderTest] alloc] initWithPath:urlString] autorelease];
//    IDEXPECT( [ref path], @"//www.metaobject.com", @"path");
    IDEXPECT( [ref URL], sourceURL, @"urls");
}


@end

