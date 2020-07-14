/* MPWObject.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


//#define LOCKING

#import <MPWObject.h>
#import "MPWObject_fastrc.h"
#import <Foundation/Foundation.h>

#define INCREMENT( x )  (x)++
#define DECREMENT( x )  (x)--


#define MPWAssert1( expr, str, arg )  
//#define MPWAssert1( expr, str, arg )  if ( !(expr) ) { NSLog( str,arg);  }
//#define MPWAssert1( expr, str, arg )  if ( !(expr) ) { [NSException raise:@"assert" format:str,arg];  }

id retainMPWObject( MPWObject *obj )
{
	MPWAssert1( [obj isMPWObject] , @"trying to retainMPWObject a %@",[obj class]);
    INCREMENT( obj->_retainCount );
    return obj;
}
void retainMPWObjects( MPWObject **objs, unsigned count )
{
    int i;
    if ( objs ) {
        for (i=0;i<count;i++) {
            MPWAssert1( [objs[i] isMPWObject] , @"trying to retainMPWObject a %@",[objs[i]  class]);
            if ( objs[i] ) {
                INCREMENT( objs[i]->_retainCount );
            }
        }
    }
}

void releaseMPWObject( MPWObject *obj )
{
    if ( obj  ) {
        MPWAssert1( [obj isMPWObject] , @"trying to releaseMPWObject a %@",[obj  class]);
        DECREMENT( obj->_retainCount);
        if ( obj->_retainCount <0 ) {
            [obj dealloc];
        }
    }
    
}

void releaseMPWObjects( MPWObject **objs, unsigned count )
{
    if ( objs ) {
        int i;
        for (i=0;i<count;i++) {
            if ( objs[i] ) {
                DECREMENT( objs[i]->_retainCount);
                if ( objs[i]->_retainCount < 0 ) {
                    MPWAssert1( [objs[i] isMPWObject] , @"trying to releaseMPWObjects a %@",[objs[i]  class]);
                    [objs[i] dealloc];
                }
            }
        }
    }
}

@implementation NSObject(isMPWObject)

-(BOOL)isMPWObject { return NO; }

@end



@implementation MPWObject
/*"
     Provides a base object when fast reference counting is needed.
"*/

-(BOOL)isMPWObject { return YES; }


+ alloc
{
    return (MPWObject *)NSAllocateObject(self, 0, NULL);
}

+ allocWithZone:(NSZone *)zone
{
    return (MPWObject *)NSAllocateObject(self, 0, zone);
}

- retain
{
    return retainMPWObject( self );
}

- (NSUInteger)retainCount
{
    return _retainCount+1;
}

- (oneway void)release
{
    releaseMPWObject(self);
}

-(NSString*)copyrightString
{
    return @"Copyright 1998-2018 by Marcel Weiher, All Rights Reserved.";
}

-(void)mydealloc
{
    [self dealloc];
}

@end

#ifndef RELEASE
#import "DebugMacros.h"

@implementation MPWObject(testing)

+(void)retaintCountAfterAlloc
{
    id mpwobj=[[MPWObject alloc] init];
    id nsobj=[[NSObject alloc] init];
    INTEXPECT( [mpwobj retainCount], [nsobj retainCount] ,@"retaincount not equal after alloc");
    [nsobj release];
    [mpwobj release];
}

+(void)retainCountSameAsNSObject
{
    id mpo=[[[MPWObject alloc] init] autorelease],nso=[[[NSObject alloc] init] autorelease];
    INTEXPECT( [nso retainCount] , [mpo retainCount], @"retainCount of NSObject MPWObject");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
			@"retaintCountAfterAlloc",@"retainCountSameAsNSObject", nil];
}

@end

static int __globalCallDummy=0;
int ___crossModuleCallBenchmarkDoNothingFunction(int dummy1,int dummy2)
{
	__globalCallDummy++;
	return __globalCallDummy;
}

#endif
