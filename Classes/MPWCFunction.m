//
//  MPWCFunction.m
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 03.05.25.
//

#import "MPWCFunction.h"
#include <dlfcn.h>

#ifndef RTLD_DEFAULT
#define RTLD_DEFAULT 0
#endif

id MPWCFunction_testfunction(void ) {
    return @"Hello MPWCFunction";
}

typedef id (*IDFNPTR0)(void);

@interface MPWCFunction()

@property (assign) IMP fnptr;

@end

@implementation MPWCFunction

-(instancetype)initWithPointer:(IMP)fnptr
{
    self=[super init];
    self.fnptr = fnptr;
    return self;
}

-(instancetype)initWithFunctionName:(NSString*)fname
{
    const char *symbol=[fname UTF8String];
    void* ptr=dlsym( RTLD_DEFAULT, symbol );
    if ( ptr )  {
        return [self initWithPointer:ptr];
    } else {
        return nil;
    }
}

-value
{
    return ((IDFNPTR0)self.fnptr)();
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWCFunction(testing) 


+(void)testCanGetFnPtr
{
    NSString *fname=@"MPWCFunction_testfunction";
    MPWCFunction *f=[[[self alloc] initWithFunctionName:fname] autorelease];
    EXPECTNOTNIL(f.fnptr, @"have a function pointer");
}

+(void)testCanCallFunction
{
    NSString *fname=@"MPWCFunction_testfunction";
    MPWCFunction *f=[[[self alloc] initWithFunctionName:fname] autorelease];
    IDEXPECT( [f value], @"Hello MPWCFunction",@"result of calling fn");
}

+(NSArray*)testSelectors
{
   return @[
			@"testCanGetFnPtr",
            @"testCanCallFunction",
			];
}

@end
