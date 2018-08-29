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
#import "MPWURLReference.h"
#import "AccessorMacros.h"

@interface MPWURLCall()

@property (nonatomic, strong)  MPWRESTOperation  *operation;

@end


@implementation MPWURLCall

CONVENIENCEANDINIT( call, WithRESTOperation:(MPWRESTOperation*)op)
{
    self=[super init];
    self.operation=op;
    if ( [op.reference isKindOfClass:[MPWURLReference class]]) {
        self.baseURL=[(MPWURLReference*)(op.reference) URL];
    }
    return self;
}

-reference
{
    return self.operation.reference;
}

-(NSString*)verb
{
    return self.operation.HTTPVerb;
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
    request.HTTPMethod=self.verb;
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
    [_data release];
    [_response release];
    [_error release];
    [_task release];
    
    [super dealloc];
}

@end
