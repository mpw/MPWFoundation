/*
    MPWFakedReturnMethodSignature.m created by marcel on Tue 27-Jul-1999
    Copyright (c) 1999-2017 by Marcel Weiher. All rights reserved.

R

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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"

-(void)dealloc
{
	free( myTypes );
    NSDeallocateObject(self);
	return;
}
#pragma clang diagnostic pop

@end
