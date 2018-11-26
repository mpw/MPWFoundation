/* MPWFlattenStream.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import "MPWFlattenStream.h"
#import <objc/runtime.h>
#import <objc/message.h>


@implementation NSObject(MPWStructureFlattening)

-(void)flattenStructureOntoStream:(MPWFlattenStream*)aStream
{
    [self flattenOntoStream:aStream];
}

@end


@implementation MPWFlattenStream


-(SEL)streamWriterMessage
{
    return @selector(flattenStructureOntoStream:);
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
    id result =[(NSArray*)[stream target] componentsJoinedByString:@""];
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



@implementation NSDictionary(MPWFlattening)

-(void)flattenStructureOntoStream:(MPWFlattenStream*)aStream
{
    [aStream writeDictionary:self];
}

@end




