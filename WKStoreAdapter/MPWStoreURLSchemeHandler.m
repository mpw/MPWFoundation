//
//  MPWStoreURLSchemeHandler.m
//  SiteBuilder
//
//  Created by Marcel Weiher on 01.03.19.
//

#import "MPWStoreURLSchemeHandler.h"
#import <MPWFoundation/MPWFoundation.h>
//#import <ObjectiveHTTPD/MPWPOSTProcessor.h>

@import ObjectiveSmalltalk;

@implementation MPWStoreURLSchemeHandler
{
    int numRedirects;
}

-(instancetype)initWithStore:(id <MPWStorage>) store
{
    self=[super init];
    self.store = store;
    NSLog(@"init MPWStoreURLSchemeHandler %p with store: %@",self,self.store);
    return self;
}

//-store {
//    return self.theStore;
//}

- (void)webView:(WKWebView *)webView startURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask
{
    NSURL *url=urlSchemeTask.request.URL;
    NSString *verb = urlSchemeTask.request.HTTPMethod;
    NSString *path=url.resourceSpecifier;
    MPWGenericIdentifier *ref=[MPWGenericIdentifier referenceWithPath:path];
    MPWResource *resource = nil;
    NSString *mimetype=@"text/html";
    @try {
        if ( [verb isEqual:@"GET"]) {
            resource = [self.store at:ref];
        } else if ( [verb isEqual:@"PUT"]) {
            self.store[ref] = urlSchemeTask.request.HTTPBody;
            resource = self.store[ref];
        } else if ( [verb isEqual:@"POST"]) {
            NSString *body=urlSchemeTask.request.HTTPBody.stringValue;
            NSMutableDictionary *d=[NSMutableDictionary dictionary];
            NSArray *keyValues=[body componentsSeparatedByString:@"&"];
            for (NSString *keyValue in keyValues) {
                NSArray *separated=[keyValue componentsSeparatedByString:@"="];
                NSString *key=separated.firstObject;
                NSString *value=[[separated lastObject] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                d[key]=value;
            }
            id postProcessor = [MPWPOSTProcessor processor];
            [postProcessor addParameters:d];
            resource = [self.store post:ref parameters:postProcessor];
//            resource = self.store[ref];
        } else {
            NSLog(@"unknown verb: '%@'",verb);
        }
    } @catch ( NSException *exception ) {
        NSString *errorDescription = [NSString stringWithFormat:@"<html><head></head><body><p>Exception: %@<p><hr><pre>%@\n%@</pre></body</html>",exception.name,exception.reason,exception.callStackSymbols];
        resource=[MPWResource new];
        resource.rawData = [errorDescription asData];
        resource.MIMEType = @"text/html";
        mimetype = @"text/html";
        [self.requestLog writeObject:exception];
//        NSLog(@"got exception: %@",exception);
//        NSRunCriticalAlertPanel(@"runtime error", @"Error: %@\n\nDetail: %@", @"ok", nil, nil,exception.name,exception.reason);
    }
//    NSLog(@"== after forwarding request to store ==");

//    NSLog(@"resource: %@",[resource stringValue]);
    if ( [path hasSuffix:@"png"]) {
        mimetype=@"image/png";
    } else if ( [path hasSuffix:@"css"]) {
        mimetype=@"text/css";
    } else if ( [path hasSuffix:@"jpg"]) {
        mimetype=@"image/jpg";
    } else if ( [path hasSuffix:@"gif"]) {
        mimetype=@"image/gif";
    }
    if ( [resource respondsToSelector:@selector(MIMEType)] ) {
        mimetype=[resource MIMEType];
    }
    NSHTTPURLResponse *response = nil;
    NSData *data=nil;;
    if ( [resource isKindOfClass:[MPWIdentifier class]] || [resource isKindOfClass:[MPWReference class]]) {
        NSString *newLocation = [resource path];
        [self.requestLog println:@" - redirect"];
        newLocation=[NSString stringWithFormat:@"special:%@",newLocation];
        if ( numRedirects++ < 10) {
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:newLocation]]];
            return ;
        } else {
            numRedirects=0;
            resource = @"Too many redirects";
            data=[resource asData];
            response = [[[NSHTTPURLResponse alloc] initWithURL:url MIMEType:mimetype expectedContentLength:[data length] textEncodingName:nil] autorelease];
        }
        
        //  instruct the web view to load the new page
        //  returning a redirect does not work
        //  https://bugs.webkit.org/attachment.cgi?id=313649&action=diff
        //
        //  relative URLs also don't seem to work, hence pre-pending special:
        //  manually.
        
    } else {
        numRedirects=0;
        data=[resource asData];
        NSDictionary *headers = @{
                                @"Cache-Control": @"no-cache, no-store, must-revalidate",
                                   @"Pragma": @"no-cache",
                                   @"Expires": @"0",
                                   @"Content-Length": [NSString stringWithFormat:@"%ld",data.length],
                                   @"Content-Type": mimetype,
        };
        response = [[[NSHTTPURLResponse alloc] initWithURL:url statusCode:200 HTTPVersion:@"HTTP/1.1"   headerFields:headers] autorelease];
    }
    [urlSchemeTask didReceiveResponse:response];
    if ( data ) {
        NSString *s=data.stringValue;
        [self.responseLog writeObject:[NSString stringWithFormat:@"\n -- response: '%@' %ld bytes: \n%@%@\n",response.MIMEType,data.length, [s substringToIndex:MIN(s.length,100)],s.length > 100 ? @"...":@""]];
        [urlSchemeTask didReceiveData:data];
    } else {
        [self.responseLog writeObject:[NSString stringWithFormat:@"no response\n"]];
    }
    [urlSchemeTask didFinish];
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask
{
    return ;
}

@end
