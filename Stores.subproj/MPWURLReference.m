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

CONVENIENCEANDINIT( reference, WithURL:(NSURL*)url )
{
    self=[super init];
    self.URL = url;
    return self;
}

CONVENIENCEANDINIT( reference, WithPath:(NSString*)pathName )
{
    return [self initWithURL:[NSURL fileURLWithPath:pathName]];
}

-(instancetype)initWithPathComponents:(NSArray *)pathComponents scheme:(NSString *)scheme
{
    NSURLComponents *components=[[NSURLComponents new] autorelease];
    components.scheme = scheme;
    components.path = [pathComponents componentsJoinedByString:@"/"];
    NSURL *url=[components URL];
    return [self initWithURL:url];
}

-(NSString *)path
{
    return self.URL.path;
}

-(NSArray *)pathComponents
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:NO];
    return [components.path componentsSeparatedByString:@"/"];
}

-(NSArray*)relativePathComponents
{
    return self.pathComponents;
}

- (instancetype)referenceByAppendingReference:(id<MPWReferencing>)other
{
   return  [[self class] referenceWithURL: [[[NSURL alloc] initWithString:[other path] relativeToURL:self.URL] autorelease]];
}
            

-(NSString*)schemeName
{
    return self.URL.scheme;
}

-(void)setSchemeName:(NSString *)schemeName
{
    [NSException raise:@"invalidaccess" format:@"cannot set the scheme of a %@",[self className]];
}

@end
