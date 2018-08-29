//
//  MPWURLCall.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 02/06/16.
//
//

#import "MPWURLCall.h"
#import "NSStringAdditions.h"
#import "MPWRESTOperation.h"

@interface MPWURLCall()

@property (nonatomic, strong)  MPWRESTOperation  *operation;
@property (nonatomic, strong)  NSURL  *baseURL;
@property (nonatomic, strong)  NSString  *verb;

@end


@implementation MPWURLCall



-(instancetype)initWithURL:(NSURL *)requestURL method:(NSString *)method data:(NSData *)bodyData
{
    self=[super init];
    self.baseURL=requestURL;
    self.verb=method;
    self.bodyData=bodyData;
    
    return self;
}

-(NSURL*)finalURL
{
    return self.baseURL;
}

-(NSURLRequest*)request
{
    NSMutableURLRequest *request=[[NSMutableURLRequest new] autorelease];
    request.allHTTPHeaderFields=self.headerDict;
    request.HTTPBody=self.bodyData;
    request.URL=self.finalURL;
    return request;
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
    [_operation release];
    [_baseURL release];
    [_verb release];
    [_ref release];
    [_data release];
    [_response release];
    [_error release];
    [_task release];
    
    [super dealloc];
}

@end
