/*
    MPWFakedReturnMethodSignature.m created by marcel on Tue 27-Jul-1999
    Copyright (c) 1999-2012 by Marcel Weiher. All rights reserved.

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


#import "MPWFakedReturnMethodSignature.h"
#import <MPWFoundation/MPWFoundation.h>
//#include <objc/runtime.h>

#ifdef Darwin
@interface NSMethodSignature(privateHacks)
#if 0
-(const char*)_types;
-(void)_setTypes:(const char*)newTypes;
#endif

@end


@implementation NSMethodSignature(privateHacks)
#if 0
-(const char*)_types
{
//	NSLog(@"getting types: %x",_types);
	return _types;
}

-(void)_setTypes:(const char*)newTypes
{	
//	NSLog(@"setting types");
	_types=newTypes;
}
#endif 
-(const char*)methodTypesWithForcedObjectReturn
{
	char *types=malloc( 200 );
	int i;
	types[0]=0;
	strcat( types, "@" );
	for (i=0;i<[self numberOfArguments]; i++ ) {
		strcat( types, [self getArgumentTypeAtIndex:i] );
	}
	return types;
}

@end
#endif

@implementation MPWFakedReturnMethodSignature

CACHING_ALLOC( fakeSignature, 20, YES )


/*
#define	FORWARDMESSAGE( type,sel, obj ) \
-(type)sel\
{\
    return [obj sel];\
}\

FORWARDMESSAGE( unsigned, numberOfArguments, signature )
FORWARDMESSAGE( unsigned, frameLength, signature )
FORWARDMESSAGE( BOOL, isOneWay, signature )
*/


- (const char *)methodReturnType
{
    return "@";
}
- (NSUInteger)methodReturnLength
{
    return 4;
}


#if 0
//+fakeSignatureWithSignature:aSignature
-initWithSignature:aSignature
{
    Class class=isa;
	int instanceSize = [class instanceSize];
//	NSLog(@"instanceSize: %d",instanceSize);
//	NSLog(@"other sig: %@",[aSignature debugDescription]);
    memcpy( self, aSignature , instanceSize );
	isa = class;
	NSLog(@"self sig: %@",[self description]);
    isa=class;
	if ( [self _types] ) {
		myTypes=malloc( strlen([self _types])+2);
		strcpy( myTypes, [self _types]);
		myTypes[0]='@';
	} else {
		myTypes=malloc( 2 );
		strcpy( myTypes,"@");
	}
	[self _setTypes:myTypes];
    return self;
}

+fakeSignatureWithSignature:aSignature
{
    return [[[self alloc] initWithSignature:aSignature] autorelease];
}
#endif


-(void)dealloc
{
	free( myTypes );
    NSDeallocateObject(self);
	return; [super dealloc];
}
@end
