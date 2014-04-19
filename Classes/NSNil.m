/* NSNil.m Copyright (c) 1998-2012 by Marcel Weiher, 

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
	 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
	 Neither the name of Marcel Weiher nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/


#import "NSNil.h"
#import <objc/runtime.h>
#include <dlfcn.h>

@implementation NSNil
/*"
    Provides an object that is considered nil.
"*/

static id nsnil=nil;
static BOOL installed=NO;

-_internalInitNil
{
    [super init];
    return self;
}

+sharedNil
{
    if (nsnil==nil) {
        nsnil = [[super allocWithZone:NULL] init];
    }
    return nsnil;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [[self sharedNil] retain];
}

+(id)nsNil { return [self sharedNil]; }

typedef id (*id2id)(id);
static id2id nil_handler=nil;

static id dummy(id arg) { return arg; }

+(id2id)nilHandlerSetter
{
//    extern id _objc_setNilReceiver(id );
    if (!nil_handler) {
        char buffer[2045];
        strcpy(buffer, "_");
        strcat(buffer, "objc_");
        strcat(buffer, "set");
        strcat(buffer, "Nil");
        strcat(buffer, "Receiver");
        
        nil_handler=dlsym(RTLD_DEFAULT, buffer);
        if (!nil_handler) {
            nil_handler=dummy;
        }
    }
    return nil_handler;
}

+(void)setNilHandler
{
    installed=YES;
    [self nilHandlerSetter]([self nsNil]);
}

+(void)unsetNilHandler
{
    installed=NO;
    [self nilHandlerSetter](nil);
}


-init
{
    return self;
}

-(BOOL)isNotNil
	/*" The reason we use isNotNil instead of isNil is that this works for plain nil as well as NSNil\
	"*/
{
    return NO;
}

-(BOOL)respondsToSelector:(SEL)selector
{
    return
    selector == @selector(isNil) ||
    selector == @selector(isNotNil) ||
    selector == @selector(ifNil:) ||
    selector == @selector(ifNotNil:);
}

-(BOOL)isNil
{
    return YES;
}


-ifNil:anArg
{
    return [anArg value];
}

-ifNotNil:anArg
{
    return installed ? nil : [NSNil nsNil];
}

-retain
{
    return self;
}

-description
{
	return @"nil";
}

-(oneway void)release
{
    ;
}

-copyWithZone:(NSZone*)aZone
{
    return self;
}


static id idresult( id receiver, SEL selector, ... )  { return nil; }

+(BOOL)resolveInstanceMethod:(SEL)selector
{
    class_addMethod(self, selector, (IMP)idresult , "@@:@");
    return YES;
}

@end

@interface NSNil(bozo)

-bozo;

@end

@implementation NSObject(Testnil)

-(BOOL)isNotNil
{
    return YES;
}

-(BOOL)isNil
{
    return NO;
}

@end

#import "DebugMacros.h"

@implementation NSNil(testing)

+(void)uniqueNil
{
    NSAssert( [NSNil nsNil] == [NSNil nsNil], @"NSNil not unique");
}

+(void)nilIsNil
{
    NSAssert( ![(id)nil isNotNil], @"nil not nil");
}

+(void)nsnilIsNil
{
    NSAssert( ![[NSNil nsNil] isNotNil], @"NSNil not nil");
}

+(void)objIsNil
{
    NSAssert( [@"" isNotNil], @"NXConstantString isNil");
}

+value
{
    return @"value";
}

+(void)testNilIfNil
{
    IDEXPECT( [[self nsNil] ifNil:self] ,@"value", @"");
}


+(void)testNilIfNotNil
{
    IDEXPECT( [[self nsNil] ifNotNil:self], [self nsNil], @"nsNil ifNil ->");
}


+(void)testNotNilIfNil
{
    IDEXPECT( [@"" ifNil:self], [self nsNil], @"");
}


+(void)testNotNilIfNotNil
{
    IDEXPECT( [@"" ifNotNil:self], @"value", @"");

}

+(void)testNilEatsMessages
{
    id mynil=[self nsNil];
    id result = @"result";
    EXPECTFALSE([mynil respondsToSelector:@selector(bozo)],@"should not respond to to bozo");
    @try {
        result = [mynil bozo];
    }
    @catch (NSException *exception) {
        EXPECTNIL(exception, @"should not have gotten exception");
    }
    EXPECTNIL(result, @"result should have been nil");
}

#if !TARGET_OS_IPHONE            

+(void)testnilReceiver
{
    [self setNilHandler];
    @try {
        IDEXPECT([(id)nil ifNil:self],@"value",@"actual nil receiver ifNil -> gets a value");
        EXPECTNIL([(id)nil ifNotNil:self], @"nil receiver ifNotNil");
    }
    @finally {
        [self unsetNilHandler];
    }
}
#endif

+testSelectors
{
    return [NSArray arrayWithObjects:
        @"uniqueNil",@"nilIsNil",@"nsnilIsNil",@"objIsNil",
            @"testNilIfNil",@"testNilIfNotNil",
            @"testNotNilIfNil",@"testNotNilIfNotNil",
            @"testNilEatsMessages",
#if !TARGET_OS_IPHONE            
            @"testnilReceiver",
#endif            
            nil
 ];
}

@end

@implementation NSObject(ifNotNil)

-ifNotNil:anArg
{
    return [anArg value];
}

-ifNil:anArg
{
    return [NSNil nsNil];
}

@end
