//
//  MPWURLReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 6/10/18.
//

#import "MPWURLReference.h"

@interface MPWURLReference()

@property (nonatomic,strong) NSString *scheme,*host;
@property (nonatomic,strong) NSArray *myPathComponents;



@end


@implementation MPWURLReference

static NSURL *url( NSString *scheme, NSString* host1, int port1, NSString *path1, NSString *path2 ) {
    NSMutableString *s=[NSMutableString string];
    if (!host1) {
        host1=@"";
    }
    if ( scheme ) {
        [s appendFormat:@"%@:",scheme];
    }
    if ( host1 ) {
        [s appendFormat:@"//%@",host1];
    }
    if ( port1 ) {
        [s appendFormat:@":%d",port1];
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
    MPWURLReference *r = [self initWithPathComponents:[newURL.path componentsSeparatedByString:@"/"] host:newURL.host scheme:newURL.scheme];
    r.port = newURL.port.intValue;
    return r;
}


CONVENIENCEANDINIT( reference, WithPath:(NSString*)pathName )
{
    pathName=[pathName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    return [self initWithPathComponents:[pathName componentsSeparatedByString:@"/"] host:nil scheme:nil];
}

- (id)asReference {
    return self;
}


- (instancetype)initWithPathComponents:(NSArray *)pathComponents scheme:(NSString *)scheme {
    return [self initWithPathComponents:pathComponents host:nil scheme:scheme];
}


-(instancetype)initWithPathComponents:(NSArray *)pathComponents host:(NSString*)host scheme:(NSString *)scheme
{
    self=[super init];
    self.myPathComponents=pathComponents ;
    self.scheme=scheme;
    self.host=host;
    return self;
}

-(NSString*)urlPath
{
    return [self.pathComponents componentsJoinedByString:@"/"] ?: @"";
}

-(NSString *)path
{
    return [[self urlPath] stringByRemovingPercentEncoding];
}

-(NSArray*)pathComponents
{
    return _myPathComponents;
}


-(NSURL *)URL
{
    NSURL *resultURL =  url(self.scheme, self.host, self.port, self.urlPath, nil);
    if ( ! resultURL || (self.path.length >0 &&  [resultURL.path length]==0)  ) {
        NSLog(@"Trouble converting components: scheme: %@ host: %@ urlPath: %@ result URL: %@ resultURL path: %@\nstack:\n%@",self.scheme,self.host,self.urlPath,resultURL,resultURL.path,[NSThread callStackSymbols]);
//        @throw [NSException exceptionWithName:@"nourl" reason:[resultURL description] userInfo:@{ @"url": resultURL }];
    }
    return resultURL;
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
    NSURL *u1=[self URL];
    NSURL *u2=[u1 URLByAppendingPathComponent:[other path]];
    return  [[self class] referenceWithURL:u2];
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

-copyWithZone:(NSZone*)aZone
{
    return [self retain];
}

-(NSString*)stringValue
{
    return [self.URL stringValue];
}

-(NSUInteger)hash
{
    return [self.URL hash];
}

-(BOOL)isEqual:(MPWURLReference*)other
{
    return [other.URL isEqual:self.URL];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: URL: %@>",[self class],self,[[self URL] description]];
}


-(void)dealloc
{
    [_scheme release];
    [_host release];
    [_myPathComponents release];
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
//    IDEXPECT( [fileRef URL], fileURL, @"urls");
    
}

+(void)testURLWithPort
{
    NSString *urlString=@"http://www.metaobject.com:50001/";
    NSURL *sourceURL=[NSURL URLWithString:urlString];
    MPWURLReference *ref=[[[[self classUnderTest] alloc] initWithURL:sourceURL] autorelease];
    ref.port=50001;
    IDEXPECT( [[ref URL] host], @"www.metaobject.com", @"host ");
    IDEXPECT( [[ref URL] port], @50001, @"port ");
    IDEXPECT( [ref URL], sourceURL, @"urls");
    
    NSString *fileURLString=@"file:/hi";
    NSURL *fileURL=[NSURL URLWithString:fileURLString];
    MPWURLReference *fileRef=[[[[self classUnderTest] alloc] initWithURL:fileURL] autorelease];
    IDEXPECT( [fileRef path], @"/hi", @"path");
//    IDEXPECT( [fileRef URL], fileURL, @"urls");
    
}

+(void)testAppendReferenceToBaseReferenceWithPort
{
    NSURL *url1=[NSURL URLWithString:@"http://localhost:50001/"];
    NSString *url2 = @"hi.txt";
    MPWURLReference *baseRef = [[MPWURLReference alloc] initWithURL:url1];
    MPWURLReference *additionalRef = [[MPWURLReference alloc] initWithPath:url2];
    
    MPWURLReference *result = [baseRef referenceByAppendingReference:additionalRef];
    IDEXPECT( [result stringValue], @"http://localhost:50001/hi.txt", @"concatenated URL ref");
}



+testSelectors
{
    return @[
        @"testURL",
        @"testURLWithPort",
        @"testAppendReferenceToBaseReferenceWithPort",
    ];
}


@end

