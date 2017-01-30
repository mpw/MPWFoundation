//
//  MPWKVCSoftPointer.m
//  MPWFoundation
//
//  Created by Marcel Weiher on Wed Oct 01 2003.
/*  
    Copyright (c) 2003-2017 by Marcel Weiher.  All rights reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

	Redistributions of source code must retain the above copyright
	notice, this list of conditions and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in
	the documentation and/or other materials provided with the distribution.

	Neither the name Marcel Weiher nor the names of contributors may
	be used to endorse or promote products derived from this software
	without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.

*/
//

#import "MPWKVCSoftPointer.h"
#import "DebugMacros.h"

@implementation MPWKVCSoftPointer

idAccessor( targetOrigin, setTargetOrigin )
idAccessor( kvcPath, setKvcPath )

-initWithTarget:initialTarget path:path
{
	self = [super init];
	[self setTargetOrigin:initialTarget];
	[self setKvcPath:path];
	return self;
}

-target
{
	return [[self targetOrigin] valueForKeyPath:[self kvcPath]];
}

-(void)dealloc
{
	[kvcPath release];
	[targetOrigin release];
	[super dealloc];
}

@end

@implementation MPWKVCSoftPointer(testing)



+(void)testFinalTarget
{
	id base = [NSDictionary dictionaryWithObjectsAndKeys:@"testValue",@"testKey",nil];
	MPWKVCSoftPointer* proxy = [[[self alloc] initWithTarget:base path:@"testKey"] autorelease];
	IDEXPECT( [proxy target], @"testValue" , @"target did not match" );
}

+(void)testPointerForObject
{
	id base = [NSDictionary dictionaryWithObjectsAndKeys:@"testValue",@"testKey",nil];
	MPWKVCSoftPointer* proxy = [base softPointerForKeyPath:@"testKey"];
	IDEXPECT( [proxy target], @"testValue" , @"target did not match" );
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testFinalTarget",
		@"testPointerForObject",
		nil];
}

@end

@implementation NSObject(kvcSoftPointer)

-softPointerForKeyPath:(NSString*)keyPath
{
	return [[[MPWKVCSoftPointer alloc] initWithTarget:self path:keyPath] autorelease];
}

@end

