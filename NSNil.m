/* NSNil.m Copyright (c) 1998-2011 by Marcel Weiher, 

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
	¥ Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	¥ Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
	¥ Neither the name of Marcel Weiher nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/


#import "NSNil.h"

@implementation NSNil
/*"
    Provides an object that is considered nil.
"*/

id nsnil=nil;

-_internalInitNil
{
    [super init];
    return self;
}

+nsNil
{
    if (nsnil==nil) {
        nsnil = [[super alloc] _internalInitNil];
    }
    return nsnil;
}

+alloc
{
    return [self nsNil];
}

+allocFromZone:(NSZone*)zone
{
    return [self nsNil];
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

-(BOOL)isNil
{
    return YES;
}

-retain
{
    return self;
}

-description
{
	return @"nil";
}

-(void)release
{
    ;
}

-copyWithZone:(NSZone*)aZone
{
    return self;
}

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


+testSelectors
{
    return [NSArray arrayWithObjects:
        @"uniqueNil",@"nilIsNil",@"nsnilIsNil",@"objIsNil",nil
 ];
}

@end
