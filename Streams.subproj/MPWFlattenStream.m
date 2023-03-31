/* MPWFlattenStream.m Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <MPWFlattenStream.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "MPWPropertyBinding.h"
#import "NSObjectAdditions.h"
#import "NSObjectFiltering.h"

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

-(void)writeDictionary1:(NSDictionary *)dict
{
    [self beginDictionary];
    for ( NSString *key in [dict allKeys]) {
        [self writeObject:dict[key] forKey:key];
    }
    [self endDictionary];
}

-(void)beginDictionary {
    //    NSLog(@"begin dictionary");
}

-(void)beginArray {
}

-(void)endArray {
}


-(void)writeInteger:(long)anInt forKey:(NSString*)aKey
{
}

-(void)endDictionary
{

}

- (void)pushContainer:(id)anObject {
}


- (void)pushObject:(id)anObject {
}


- (void)writeInteger:(long)number {
}


- (void)writeKey:(id)aKey {
}


- (void)writeNumber:(id)aNumber {
}


- (void)writeString:(id)aString {
    FORWARD(aString);
}

-(void)createEncoderMethodForClass:(Class)theClass
{
    NSArray *ivars=[theClass allIvarNames];
    if ( [[ivars lastObject] hasPrefix:@"_"]) {
        ivars=(NSArray*)[[ivars collect] substringFromIndex:1];
    }
    
    NSMutableArray *copiers=[[NSMutableArray arrayWithCapacity:ivars.count] retain];
    for (NSString *ivar in ivars) {
        MPWPropertyBinding *accessor=[[MPWPropertyBinding valueForName:ivar] retain];
        [ivar retain];
        [accessor bindToClass:theClass];
        
        id objBlock=^(id object, MPWFlattenStream* stream){
            [stream writeObject:[accessor valueForTarget:object] forKey:ivar];
        };
        id intBlock=^(id object, MPWFlattenStream* stream){
            [stream writeInteger:[accessor integerValueForTarget:object] forKey:ivar];
        };
        int typeCode = [accessor typeCode];
        
        if ( typeCode == 'i' || typeCode == 'q' || typeCode == 'l' || typeCode == 'B' ) {
//            NSLog(@"int block for %@ (type:%c)",ivar,typeCode);
            [copiers addObject:Block_copy(intBlock)];
        } else {
//            NSLog(@"object block for %@ (type:%c)",ivar,typeCode);
            [copiers addObject:Block_copy(objBlock)];
        }
    }
    void (^encoder)( id object, MPWFlattenStream *writer) = Block_copy( ^void(id object, MPWFlattenStream *writer) {
        for  ( id block in copiers ) {
            void (^encodeIvar)(id object, MPWFlattenStream *writer)=block;
            encodeIvar(object, writer);
        }
    });
    void (^encoderMethod)( id blockself, MPWFlattenStream *writer) = ^void(id blockself, MPWFlattenStream *writer) {
        [writer writeDictionaryLikeObject:blockself withContentBlock:encoder];
    };
    IMP encoderMethodImp = imp_implementationWithBlock(encoderMethod);
    class_addMethod(theClass, [self streamWriterMessage], encoderMethodImp, "v@:@" );
}


-(void)writeDictionaryLikeObject:anObject withContentBlock:(void (^)(id object, MPWFlattenStream* writer))contentBlock
{
    [self beginDictionary];
    @try {
        contentBlock(anObject, self);
    } @finally {
        [self endDictionary];
    }
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

-(void)flattenOntoStream:(MPWFlattenStream*)aStream
{
//    NSLog(@"dictionary flattenOntoStream: %@",aStream);
    [aStream writeDictionary:self];
}

@end

@implementation NSString(MPWFlattening)

-(void)flattenOntoStream:(MPWFlattenStream*)aStream
{
    //    NSLog(@"dictionary flattenOntoStream: %@",aStream);
    [aStream writeString:self];
}

@end


