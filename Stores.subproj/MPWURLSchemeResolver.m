//
//  MPWURLSchemeResolver.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 6/11/08.
//  Copyright 2008 Apple. All rights reserved.
//

#import "MPWURLSchemeResolver.h"
#import "MPWURLBinding.h"
#import "MPWResource.h"

@interface MPWURLSchemeResolver ()

@property (nonatomic,strong) NSString* schemePrefix;

@end


@implementation MPWURLSchemeResolver

-(instancetype)initWithSchemePrefix:(NSString *)schemeName
{
    self=[super init];
    self.schemePrefix=schemeName;
    return self;
}

-(instancetype)init
{
    return [self initWithSchemePrefix:@"http"];
}

+(instancetype)httpScheme
{
    return [[[self alloc] initWithSchemePrefix:@"http"] autorelease];
}

+(instancetype)httpsScheme
{
    return [[[self alloc] initWithSchemePrefix:@"https"] autorelease];
}

-(id)referenceForPath:(NSString *)name
{
    NSString *combined=name;
    if ( [name hasPrefix:@"//"]) {
        combined = [NSString stringWithFormat:@"%@:%@",[self schemePrefix],name];
    }
    NSURL *u=[NSURL URLWithString:combined];
    return [MPWURLReference referenceWithURL:u];
//    id <MPWReferencing> reference=[super referenceForPath:name];
//    reference.schemeName=[self schemePrefix];
//    return reference;
}


-(MPWURLBinding*)bindingForReference:aReference inContext:aContext
{
    return [MPWURLBinding bindingWithReference:aReference inStore:self];
}

-(id)at:(id)aReference
{
    
    NSURL *aURL=[aReference URL];
//    NSLog(@"get, ref: %@ - url: %@",aReference,aURL);
#ifdef GS_API_LATEST
    NSData *rawData = [NSData dataWithContentsOfURL:aURL];
    MPWResource *result=[[[MPWResource alloc] init] autorelease];
    [result setSource:aURL];
    [result setRawData:rawData];
//    [result setError:error];
#else
//    NSData *rawData=nil;
//    if ( [aURL.scheme hasPrefix:@"http"]) {
//        rawData = [self atURL:aURL];
//    } else {
//        rawData = [NSData dataWithContentsOfURL:aURL  options:NSDataReadingMapped error:&error];
//    }
    MPWResource *result=[self atURL:aURL];
#endif
    return result;
}

-(void)at:(MPWURLReference*)aReference put:(id)theObject
{
    //    NSLog(@"PUT, ref: %@ - url: %@",aReference,[aReference URL]);
    [self atURL:[aReference URL] put:[theObject asData]];
}

-(void)deleteAt:(MPWURLReference*)aReference
{
    [self deleteAtURL:[aReference URL]];
}

-(id)at:(MPWURLReference*)aReference post:(id)theObject
{
    if ( [theObject isKindOfClass:[NSDictionary class]]) {
        return [self atURL:[aReference URL] postDictionary:theObject];
    } else {
        return [self atURL:[aReference URL] post:[theObject asData]];
    }
}

///----- support for HOM-based argument-construction

-(NSString*)mimeTypeForData:(NSData*)rawData andResponse:(NSURLResponse*)aResponse
{
    NSString *mime = [aResponse MIMEType];
    const char *ptr=[rawData bytes];
    if ( ptr && [rawData length]) {
        if (( !mime ||  [mime isEqualToString:@"text/html"] ||  [mime isEqualToString:@"text/plain"] )&& (*ptr == '{' || *ptr == '[' )) {
            mime=@"application/json";
        }
    }
    return mime;
}

-(MPWResource*)resourceWithRequest:(NSURLRequest*)request
{
    NSHTTPURLResponse *response=nil;
    NSError *localError=nil;
//    NSLog(@"request headers: %@",[request allHTTPHeaderFields]);
//    NSLog(@"request URL: %@",request.URL);
    NSData *rawData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
//    NSLog(@"response: %@",response);
//    NSLog(@"rawData: %@",[rawData stringValue]);

    if ( [response statusCode] != 404 ) {
        MPWResource *result=[[[MPWResource alloc] init] autorelease];
        [result setSource:[request URL]];
        [result setRawData:rawData];
        [result setMIMEType:[self mimeTypeForData:rawData andResponse:response]];
        return result;
    } else {
        return nil;
    }
}

-(NSMutableURLRequest*)requestForURL:(NSURL*)aURL
{
    NSMutableURLRequest *request=[[[NSMutableURLRequest alloc] initWithURL:aURL] autorelease];
    NSMutableDictionary *headers=[NSMutableDictionary dictionaryWithObject:@"locale=en-us" forKey:@"Cookies"];
    [headers setObject:@"stsh" forKey:@"User-Agent"];
    [headers setObject:@"*/*" forKey:@"Accept"];
    if ( self.headers ) {
        [headers addEntriesFromDictionary:self.headers];
    }
    //    NSLog(@"headers: %@",headers);
    [request setAllHTTPHeaderFields:headers];
    //    NSLog(@"request headers: %@",[request allHTTPHeaderFields]);
    return request;
}

-atURL:(NSURL*)aURL
{
    return [self resourceWithRequest:[self requestForURL:aURL]];
}

-deleteAtURL:(NSURL*)aURL
{
    NSMutableURLRequest *request=[self requestForURL:aURL];
    request.HTTPMethod = @"DELETE";
    return [self resourceWithRequest:request];
}

-atURL:(NSURL*)aURL put:(NSData*)data
{
    NSMutableURLRequest *request=[self requestForURL:aURL];
    request.HTTPMethod = @"PUT";
    request.HTTPBody = data;
    return [self resourceWithRequest:request];
}


-(NSData*)encodeData:data asPOSTFormithName:(NSString*)postName boundary:(NSString*)boundary
{
    
    
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n\r\n", postName, postName] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:data];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return postData;
}

-atURL:(NSURL*)aURL post:(NSData*)data
{
    NSMutableURLRequest *request=[self requestForURL:aURL];
//    NSLog(@"url: %@",aURL);
    request.HTTPMethod = @"POST";
    request.HTTPBody = data;
    return [self resourceWithRequest:request];
}


-(NSData *)formEncodeDictionary:(NSDictionary*)aDict
{
    MPWByteStream *s=[MPWByteStream stream];
    BOOL first=YES;
    //    NSLog(@"should encode dictionary: %@",aDict);
    for ( NSString *key in aDict.allKeys ) {
        [s printFormat:@"%@%@=%@",first?@"":@"&", key,aDict[key]];
        first=NO;
    }
    //    NSLog(@"encoded dict: '%@'",[[s target] stringValue]);
    return (NSData*)[s target];
}

-atURL:(NSURL*)aURL postDictionary:(NSDictionary*)dict
{
    NSMutableURLRequest *request=[self requestForURL:aURL];
    NSString *boundary=@"0xKhTmLbOuNdArY";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [self formEncodeDictionary:dict];
    return [self resourceWithRequest:request];
}



-(void)dealloc
{
    [_schemePrefix release];
    [super dealloc];
}


@end


@implementation MPWURLSchemeResolver(tests)


+(void)testScuritySetting
{
    IDEXPECT( [[self httpScheme] schemePrefix], @"http",@"insecure");
    IDEXPECT( [[self httpsScheme] schemePrefix], @"https",@"secure");
    IDEXPECT( [[(MPWGenericReference*)[[self httpsScheme] referenceForPath:@"localhost"] URL] absoluteString], @"https://localhost",@"secure");
    IDEXPECT( [[(MPWGenericReference*)[[[[self alloc] initWithSchemePrefix:@"ftp" ] autorelease] referenceForPath:@"localhost"] URL] absoluteString], @"ftp://localhost" ,@"ftp");
    
}

+(NSArray*)testSelectors
{
    return @[
//             @"testScuritySetting",
             ];
}

@end
