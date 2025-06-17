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
    NSLog(@"URL handler: %@ %@ %@",verb,path,urlSchemeTask.request);
    MPWGenericIdentifier *ref=[MPWGenericIdentifier referenceWithPath:path];
    MPWResource *resource = nil;
    NSString *mimetype=@"text/html";
    @try {
        if ( [verb isEqual:@"GET"]) {
            resource = [self.store at:ref];
        } else if ( [verb isEqual:@"PUT"]) {
            NSLog(@"PUT %@",urlSchemeTask.request.HTTPBody);
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
        NSLog(@"got exception: %@",exception);
        NSString *errorDescription = [NSString stringWithFormat:@"<html><head></head><body><p>Exception: %@<p><hr><pre>%@\n%@</pre></body</html>",exception.name,exception.reason,exception.callStackSymbols];
        resource=[MPWResource new];
        resource.rawData = [errorDescription asData];
        resource.MIMEType = @"text/html";
        mimetype = @"text/html";
        [self.requestLog writeObject:exception];
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
        [self.responseLog writeObject:[NSString stringWithFormat:@"\n\n== no response ==\n"]];
    }
    [urlSchemeTask didFinish];
}

- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask
{
    return ;
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    NSRunAlertPanel(@"Alert", @"JavaScript: %@", @"OK", nil,nil,message);
    completionHandler();
}

- (void) userContentController:(WKUserContentController *) userContentController
       didReceiveScriptMessage:(WKScriptMessage *) message {
    
    if ( [message.name isEqual:@"jsLogger"]) {
        NSLog(@"jsconsole: %@",message.body);
    }
}

- (void) userContentController:(WKUserContentController *) userContentController
       didReceiveScriptMessage:(WKScriptMessage *) message replyHandler:(nonnull WK_SWIFT_UI_ACTOR void (^)(id _Nullable, NSString * _Nullable))replyHandler
{
    
    if ( [message.name isEqual:@"request"]) {
        NSArray *request = message.body;
        NSLog(@"request: %@",message.body);
        NSString *verb=request[0];
        NSLog(@"verb: %@",verb);
        NSString *uristring=request[1] ;
        uristring=[[uristring componentsSeparatedByString:@":"] lastObject];
        MPWGenericIdentifier *ref = [MPWGenericIdentifier referenceWithPath:uristring];
        id data=[NSString stringWithFormat:@"unknown verb %@",verb];
        if ( [[verb uppercaseString] isEqualToString:@"GET"])  {
            data = [self.store at:ref];
        } else if ( [[verb uppercaseString] isEqualToString:@"PUT"]) {
            NSLog(@"PUT");
            NSLog(@"PUT with data:\n'%@'\n",request[2]);
            NSMutableDictionary *formDict = [NSMutableDictionary dictionary];
            NSArray *components = [request[2] componentsSeparatedByString:@"&"];
            for ( NSString *comp in components ) {
                NSArray *keyval=[[comp  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] componentsSeparatedByString:@"="];
                formDict[keyval[0]]=keyval[1];
            }
            [self.store at:ref put:formDict];
            data = [self.store at:ref];
        } else {
            NSLog(@"unknown verb: %@",verb);
        }
        NSLog(@"store: %@ uri: '%@'",self.store,ref);
        id resultString = [data stringValue];
        NSLog(@"resultString: '%@'",resultString);
        resultString = resultString ?: @"NULL";
        replyHandler( @{ @"Headers": @{ @"Content-Type": @"text/html", @"Content-Length": @([resultString length]) } , @"Body": resultString } , nil);
        NSLog(@"did send reply");
    }
}


-(WKWebView*)setupWebViewWithFrame:(NSRect)viewFrame
{
    WKWebViewConfiguration *config=[WKWebViewConfiguration new];
    [config setURLSchemeHandler:self forURLScheme:@"special"];
    
    WKUserContentController *bridge = [[WKUserContentController alloc] init];
    [bridge addScriptMessageHandlerWithReply:self contentWorld:[WKContentWorld pageWorld]
                                        name:@"request"];
    [bridge addScriptMessageHandler:self contentWorld:[WKContentWorld pageWorld]
                               name:@"sendRequest"];
    [bridge addScriptMessageHandler:self contentWorld:[WKContentWorld pageWorld]
                               name:@"jsLogger"];
    NSString *js=[[self frameworkResource:@"inject" category:@"js"] stringValue];
    [bridge addUserScript:[[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO]];
    [config setUserContentController:bridge];
    id view = [[WKWebView alloc] initWithFrame:viewFrame configuration:config];
    
    return view;
}


@end
