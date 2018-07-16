//
//  MPWURLReference.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 6/10/18.
//

#import "MPWURLReference.h"

@interface MPWURLReference()

@property (nonatomic, strong) NSURLComponents *components;

@end


@implementation MPWURLReference

CONVENIENCEANDINIT( reference, WithURLComponents:(NSURLComponents*)urlComponents )
{
    self=[super init];
    self.components = urlComponents;
    return self;
}

CONVENIENCEANDINIT( reference, WithPath:(NSString*)pathName )
{
    NSURLComponents *comps=[NSURLComponents componentsWithString:pathName];
    return [self initWithURLComponents:comps];
}

-(instancetype)initWithPathComponents:(NSArray *)pathComponents scheme:(NSString *)scheme
{
    NSURLComponents *components=[[NSURLComponents new] autorelease];
    components.scheme = scheme;
    components.path = [pathComponents componentsJoinedByString:@"/"];
    return [self initWithURLComponents:components];
}

-(NSURL*)URL
{
    return self.components.URL;
}

-(NSString *)path
{
    return self.components.path;
}

-(NSArray *)pathComponents
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:NO];
    NSArray *pathComponents = [components.path componentsSeparatedByString:@"/"];
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
    
    
    NSURLComponents *combined=[[self.components copy] autorelease];
    combined.path = [[[self pathComponents] arrayByAddingObjectsFromArray:[other relativePathComponents]] componentsJoinedByString:@"/"];
    
   return  [[self class] referenceWithURLComponents:combined];
}
            

-(NSString*)schemeName
{
    return self.URL.scheme;
}

-(void)setSchemeName:(NSString *)schemeName
{
    self.components.scheme = schemeName;
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
    return [[self components] isEqual:[other components]];
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
    MPWGenericReference *ref=[[[self classUnderTest] alloc] initWithPath:urlString];
//    IDEXPECT( [ref path], @"//www.metaobject.com", @"path");
    IDEXPECT( [ref URL], sourceURL, @"urls");
}


@end

