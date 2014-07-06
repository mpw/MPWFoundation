/* MPWFlattenStream.m Copyright (c) 1998-2012 by Marcel Weiher, All Rights Reserved.


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


#import "MPWFlattenStream.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation MPWFlattenStream

+(void)initialize
{
#if 0
    Class NSObjectClass = [NSObject class];
    SEL superMessage;
    IMP skewIMP = imp_implementationWithBlock(^(id _s, id stream) { objc_msgSend( _s, superMessage,stream); });
#endif
}

-(SEL)streamWriterMessage
{
    return @selector(flattenOntoStream:);
}

-(void)writeArray:(NSArray*)anArray
{
    [[anArray objectEnumerator] writeOnStream:self];
}

-(void)writeObject:anObject forKey:aKey
{
    [anObject writeOnStream:self];
}

-(void)writeKeyEnumerator:(NSEnumerator*)keys withDict:(NSDictionary*)dict
{
    id nextKey;
    while (nil!=(nextKey = [keys nextObject])) {
        [self writeObject:[dict objectForKey:nextKey] forKey:nextKey];
    }
}

-(void)writeDictionary:(NSDictionary*)dict
{
	[self writeKeyEnumerator:[dict keyEnumerator] withDict:dict];
}

@end
#import "DebugMacros.h"

@implementation MPWFlattenStream(testing)

+(void)testNestedArrayFlattening
{
    MPWFlattenStream* stream=[MPWFlattenStream stream];
    id source = [NSArray arrayWithObjects:[NSArray arrayWithObjects:@"a",@"b",nil]
        ,@"c",@"d",[NSArray arrayWithObjects:@"e",@"f",nil],nil];
    [stream writeObject:source];
    id result =[[stream target] componentsJoinedByString:@""];
    IDEXPECT(result, @"abcdef", @"result not flattened");
}

+(void)testNestedDictFlatteningWithProcess
{
    id source = [@" { first={ name=a; value=b; }; second={ hello=world; foo=bar; }; } " propertyList];
    NSSet* correctResult=[NSSet setWithObjects:@"a",@"b",@"world",@"bar",nil];
    NSSet* actualResult;
    actualResult=[NSSet setWithArray:[MPWFlattenStream process:source]];
    IDEXPECT(actualResult,correctResult,@"nested dict flattening");
}

+testSelectors
{
    return [NSArray arrayWithObjects:@"testNestedArrayFlattening",@"testNestedDictFlatteningWithProcess",
        nil];
}


@end


@implementation NSArray(MPWFlattening)

-(void)flattenOntoStream:(MPWFlattenStream*)aStream
{
    [aStream writeArray:self];
}

@end

@implementation NSDictionary(MPWFlattening)

-(void)flattenOntoStream:(MPWFlattenStream*)aStream
{
    [aStream writeDictionary:self];
}

@end



@implementation NSEnumerator(MPWFlattening)

-(void)flattenOntoStream:(MPWFlattenStream*)aStream
{
    [aStream writeEnumerator:self];
}

@end

@implementation NSObject(MPWFlattening)

-(void)flattenOntoStream:(MPWFlattenStream*)aStream
{
    [aStream writeNSObject:self];
}

@end



