//
//  MPWURLRequest.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02/06/16.
//
//

#import "MPWURLRequest.h"

@implementation MPWURLRequest

-(instancetype)initWithURL:(NSURL *)requestURL method:(NSString *)method data:(NSData *)bodyData
{
    self=[super init];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:requestURL];
    request.HTTPMethod=method;
    request.HTTPBody=bodyData;
    self.request = request;
    
    return self;
}

-(void)setHeaderDict:(NSDictionary *)headerDict
{
    NSMutableURLRequest *r=[self.request mutableCopy];
    r.allHTTPHeaderFields=headerDict;
    self.request=[r autorelease];
}

-(void)setBodyData:(NSData *)bodyData
{
    NSMutableURLRequest *r=[self.request mutableCopy];
    r.HTTPBody=bodyData;
    self.request=[r autorelease];
}

-(id)processed
{
    return [self data];
}

-(NSString *)description1
{
    return [NSString stringWithFormat:@"<%@:%p: url=%@ method: %@ responseData='%@' error: %@>",
            [self class],self,[self.request.URL absoluteString],self.request.HTTPMethod,
            [self.request.HTTPBody stringValue],self.error];
}

-(void)dealloc
{
    [_data release];
    [_request release];
    [_response release];
    [_error release];
    [_task release];
    
    [super dealloc];
}

@end
