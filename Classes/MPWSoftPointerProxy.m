//
//  MPWSoftPointerProxy.m
//  MPWFoundation
//
//  Created by Marcel Weiher on Wed Oct 01 2003.
/*  
    Copyright (c) 2003-2012 Marcel Weiher.  All rights reserved.
*/

//

#import "MPWSoftPointerProxy.h"
#import "MPWKVCSoftPointer.h"
#import "DebugMacros.h"

@implementation MPWSoftPointerProxy

objectAccessor(MPWKVCSoftPointer*, xxxsoftPointer, xxxsetSoftPointer )


+proxyWithSoftPointer:softPointer
{
	return [[[self alloc] initWithSoftPointer:softPointer] autorelease];
}

-initWithSoftPointer:softPointer
{
	[self xxxsetSoftPointer:softPointer];
	return self;
}

-xxxtarget
{
	return [[self xxxsoftPointer] target];
}

-(void)forwardInvocation:(NSInvocation*)invocationToForward
{
	[invocationToForward invokeWithTarget:[self xxxtarget]];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *sig;
    sig = [[self xxxtarget] methodSignatureForSelector:aSelector];
    return sig;
}

-(void)dealloc
{
	[xxxsoftPointer release];
	[super dealloc];
}

@end

@implementation NSObject(proxyForKeyPath)

-proxyForKeyPath:(NSString*)keyPath
{
	return [MPWSoftPointerProxy proxyWithSoftPointer:[self softPointerForKeyPath:keyPath]];
}

@end


@interface _SoftPointerProxyTesting : NSObject
{
}
@end

@implementation _SoftPointerProxyTesting : NSObject

+(void)testBasicForward
{
	id testValue = @"testValue";
	id testKey = @"testKey";
	id base = [NSDictionary dictionaryWithObjectsAndKeys:testValue,testKey,nil];
	id softPointer = [base softPointerForKeyPath:testKey];
	id proxy = [MPWSoftPointerProxy proxyWithSoftPointer:softPointer];
	INTEXPECT( [proxy length], [testValue length], @"length did not match" );
//	IDEXPECT( proxy, testValue, @"proxy did not match testValue" );
}

+(void)testProxyForKeyPath
{
	id testValue = @"testValue";
	id testKey = @"testKey";
	id base = [NSDictionary dictionaryWithObjectsAndKeys:testValue,testKey,nil];
	id proxy = [base proxyForKeyPath:testKey];
	INTEXPECT( [proxy length], [testValue length], @"length did not match" );
//	IDEXPECT( proxy, testValue, @"proxy did not match testValue" );
}


+(void)testProxyTracksChanges
{
	id testValue = @"testValue";
	id testValue2 = @"testValue2";
	id testKey = @"testKey";
	NSMutableDictionary* base = [NSMutableDictionary dictionaryWithObjectsAndKeys:testValue,testKey,nil];
	id proxy = [base proxyForKeyPath:testKey];
	INTEXPECT( [proxy length], [testValue length], @"length did not match first value" );
//	IDEXPECT( proxy, testValue, @"proxy did not match first testValue" );
	[base setObject:testValue2 forKey:testKey];
	INTEXPECT( [proxy length], [testValue2 length], @"length did not match second value" );
//	IDEXPECT( proxy, testValue2, @"proxy did not match second testValue" );
}




+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testBasicForward",
		@"testProxyForKeyPath",
		@"testProxyTracksChanges",
		nil];
}

@end
