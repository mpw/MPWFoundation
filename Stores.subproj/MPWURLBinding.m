//
//  MPWURLBinding.m
//  MPWShellScriptKit
//
//  Created by Marcel Weiher on 20.1.10.
//  Copyright 2010 Marcel Weiher. All rights reserved.
//

#import "MPWURLBinding.h"
#import <MPWFoundation/MPWSocketStream.h>
#import "MPWDirectForwardingTrampoline.h"
#import "MPWGenericReference.h"
#import "MPWURLFetchStream.h"
#import "MPWURLCall.h"
#import "MPWURLReference.h"
#import "MPWBytesToLines.h"
#import "MPWSkipFilter.h"

@interface SayYES : NSObject
{
	id target;
}
idAccessor_h( target, setTarget )

@end

@implementation SayYES 
idAccessor( target, setTarget )

-(BOOL)respondsToSelector:(SEL)selector { return YES; }
-getWithArgs:(NSInvocation*)inv
{
    NSLog(@"getWithArgs:%@",inv);
    NSLog(@"sending to target: %@",target);
	return [target getWithArgs:inv];
}
-methodSignatureForSelector:(SEL)aSelector
{
	static char *sigsByArgNum[]={
		"@@:", 
		"@@:@", 
		"@@:@@", 
		"@@:@@@", 
		"@@:@@@@", 
		"@@:@@@@@", 
		"@@:@@@@@@", 
			
	};
	const char *selname=sel_getName(aSelector);
	int numargs=0;
	do {
		if ( *selname == ':' ) {
			numargs++;
		}
	} while ( *selname++ );
	return [NSMethodSignature signatureWithObjCTypes:sigsByArgNum[numargs]];
}

-(void)dealloc
{
	[target release];
	[super dealloc];
}
@end

@implementation MPWURLBinding

objectAccessor(NSError*, error, setError)

-(BOOL)isBound
{
	return YES;
}



-getWithArgs
{
//  NSLog(@"getWithArgs");
	id yes=[[[SayYES alloc] init] autorelease];
	MPWTrampoline	*trampoline=[MPWTrampoline quickTrampoline];
	[yes setTarget:self];
	[trampoline setXxxTarget:yes];
	[trampoline setXxxSelector:@selector(getWithArgs:)];
	return trampoline;
}

-urlWithArgsFromSelectorString:(NSString*)selectorString args:(NSArray*)args
{
	int i;
	NSMutableString *result=[NSMutableString string];
	NSString *separator=@"?";
	NSArray *argKeys=[selectorString componentsSeparatedByString:@":"];
	NSAssert2( ([argKeys count]-1) == [args count], @"number of args not same: %p %p",argKeys,args);
	for (  i=0;i<[args count]; i++) {
		[result appendFormat:@"%@%@=%@",separator,[argKeys objectAtIndex:i],[[args objectAtIndex:i] stringByAddingPercentEscapesUsingEncoding:
																			 NSASCIIStringEncoding]];
		separator=@"&";
	}
	return result;
}

//-getWithArgs:(NSInvocation*)inv
//{
//    NSString *selname=NSStringFromSelector([inv selector]);
//    NSMutableArray *args=[NSMutableArray array];
//    long i,max=[[inv methodSignature] numberOfArguments];
//    for (i=2; i<max; i++) {
//        id arg=nil;
//        [inv getArgument:&arg atIndex:i];
//        if ( !arg ) {
//            NSLog(@"nil arg at %ld",i);
//            arg=@"";
//        }
//        [args addObject:arg];
//    }
//    id query = [self urlWithArgsFromSelectorString:selname args:args];
//    NSURL *fullURL=[NSURL URLWithString:[[[self URL] stringValue] stringByAppendingString:query]];
//    id result= [self.store _valueWithURL:fullURL];
//    [inv setReturnValue:&result];
//    return result;
//}

-fileSystemValue
{
    return [NSDictionary dictionaryWithObject:[[self URL] stringValue] forKey:@"URL"];
}

#define STORE   ((MPWURLSchemeResolver*)self.store)

-(void)put:(NSData*)data
{
    [STORE at:self.reference put:data];
}

-(void)post:(NSData*)data
{
    [STORE at:self.reference post:data];
}

//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    inPOST=NO;
//}

//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)localError
//{
//    inPOST=NO;
//    [self setError:localError];
//}

//-(void)_setValue:newValue
//{
//    if (newValue) {
//        [self put:newValue];
//    }
//}

//-stream
//{
//    return [[[MPWSocketStream alloc] initWithURL:[self URL]] autorelease];
//}

-stream
{
    MPWRESTOperation<MPWURLReference*>* op=[MPWRESTOperation operationWithReference:self.reference verb:MPWRESTVerbGET];
    MPWURLCall *request=[[[MPWURLCall alloc] initWithRESTOperation:op] autorelease];
    request.isStreaming=YES;
    MPWURLStreamingStream *s=[MPWURLStreamingStream streamWithTarget:nil];
    [s enqueueRequest:request];
    return s;
}



-lines
{
    MPWURLStreamingStream *s=[self stream];
    [s setTarget:[MPWBytesToLines stream]];
    return s;
}

-linesAfter:(int)numToSkip
{
    MPWURLStreamingStream *stream=[self lines];
    MPWSkipFilter *skipper=[MPWSkipFilter stream];
    skipper.skip = numToSkip;
    [stream setFinalTarget:skipper];
    return stream;
}


-(NSString *)description
{
    return [[self URL] absoluteString];
}

@end

#import "DebugMacros.h"

@implementation MPWURLBinding(testing)

+(void)testURLArgsFromSelectorAndArgs
{
    MPWGenericReference *ref=[MPWGenericReference referenceWithPath:@"//ajax.googleapis.com/ajax/services/language/translate" ];
    ref.schemeName=@"http";
    MPWURLBinding *binding=[self bindingWithReference:ref inStore:nil];
    
	NSString *pathArgs=[binding urlWithArgsFromSelectorString:@"v:langpair:q:" 
													 args:[NSArray arrayWithObjects:@"1.0",@"en|de",@"Delete",nil]];
	IDEXPECT( pathArgs, @"?v=1.0&langpair=en%7Cde&q=Delete", @"basic path args" );
	pathArgs=[binding urlWithArgsFromSelectorString:@"v:langpair:q:" 
									  args:[NSArray arrayWithObjects:@"1.1",@"en|de",@"Delete file.",nil]];
	IDEXPECT( pathArgs, @"?v=1.1&langpair=en%7Cde&q=Delete%20file.", @"path args with space" );
}

+(NSArray*)testSelectors
{
	return [NSArray arrayWithObjects:
				@"testURLArgsFromSelectorAndArgs",
			nil];
	
}

@end
