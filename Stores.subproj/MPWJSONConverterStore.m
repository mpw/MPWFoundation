//
//  MPWJSONConverterStore.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 25.05.21.
//

#import "MPWJSONConverterStore.h"

@interface MPWJSONConverterStore()

@property (nonatomic, strong) MPWJSONWriter *writer;
@property (nonatomic, strong) MPWMASONParser *reader;

@end


@implementation MPWJSONConverterStore

-(instancetype)initWithSource:(NSObject<MPWStorage,MPWHierarchicalStorage> *)newSource
{
    self=[super initWithSource:newSource];
    self.writer = [MPWJSONWriter stream];
    self.reader = [MPWMASONParser parser];
    return self;
}

-(id)parsedJSON:(NSData*)json
{
    [self.writer setTarget:[NSMutableArray array]];
    [self.writer writeObject:json];
    return self.writer.target;
}

-(void)setClass:(Class)aClass
{
    self.reader = [[[MPWMASONParser alloc] initWithClass:aClass] autorelease];
}

-(NSData*)serialized:(id)anObject
{

    return [self.reader parsedData:anObject];
}

-(id)mapRetrievedObject:(id)anObject forReference:(id<MPWReferencing>)aReference
{
    return self.toJSONUp ? [self parsedJSON:anObject] : [self serialized:anObject];
}

-(id)mapObjectToStore:(id)anObject forReference:(id<MPWReferencing>)aReference
{
    return self.toJSONUp ? [self serialized:anObject] : [self parsedJSON:anObject];
}

@end



#import <MPWFoundation/DebugMacros.h>

@interface MPWJSONCodingStoreTestClass : NSObject {}
@property (assign) long a,b;
@property (strong) id c;
@end
@implementation MPWJSONCodingStoreTestClass
@end


@implementation MPWJSONConverterStore(testing) 

+(void)testConvertDictToJSONDown
{
    NSArray *dicts=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    NSData *json=[store mapObjectToStore:dicts forReference:nil];
    IDEXPECT( [json stringValue], @"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]", @"json for dict");
}

+(void)testConvertJSONtoDictUp
{
    NSString *jsonSource=@"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]";
    NSArray *expected=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    NSArray *parsed=[store mapRetrievedObject:[jsonSource asData] forReference:nil];
    IDEXPECT(parsed, expected, @"dicts for JSON");
}

+(void)testConvertDictToJSONUp
{
    NSArray *dicts=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    store.toJSONUp=true;
    NSData *json=[store mapRetrievedObject:dicts forReference:nil];
    IDEXPECT( [json stringValue], @"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]", @"json for dict");
}

+(void)testConvertJSONtoDictDown
{
    NSString *jsonSource=@"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]";
    NSArray *expected=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    store.toJSONUp=true;
    NSArray *parsed=[store mapObjectToStore:[jsonSource asData] forReference:nil];
    IDEXPECT(parsed, expected, @"dicts for JSON");
}


+(void)testConvertDictToJSONDownToSource
{
    NSArray *dicts=@[
        @{ @"Key1":  @"Value1" , @"Key2":  @(15) },
        @{ @"Key1":  @"Value2" , @"Key2":  @(42)},
        
    ];
    MPWDictStore *d = [MPWDictStore store];
    MPWJSONConverterStore *store=[self storeWithSource:d];
    store[@"hi.json"]=dicts;
    IDEXPECT( [d[@"hi.json"] stringValue], @"[{\"Key2\":15, \"Key1\":\"Value1\"},{\"Key2\":42, \"Key1\":\"Value2\"}]", @"json for dict");
}

+(void)testConvertJSONtoObjectUp
{
    NSString *jsonSource=@"[{\"a\":15, \"b\":13, \"c\":\"TestString1\"},{\"a\":42,\"b\":1, \"c\":\"TestString2\"}]";
    MPWJSONConverterStore *store=[self storeWithSource:nil];
    [store setClass:[MPWJSONCodingStoreTestClass class]];
    NSArray *parsed=[store mapRetrievedObject:[jsonSource asData] forReference:nil];
    INTEXPECT(parsed.count, 2, @"number of objects");
    MPWJSONCodingStoreTestClass *first,*last;
    first=parsed.firstObject;
    last=parsed.lastObject;
    INTEXPECT(first.a, 15, @"first.a");
    INTEXPECT(first.b, 13, @"first.b");
    IDEXPECT(first.c, @"TestString1", @"first.c");
    INTEXPECT(last.a, 42, @"last.a");
    INTEXPECT(last.b, 1, @"last.b");
    IDEXPECT(last.c, @"TestString2", @"last.c");
}



+(NSArray*)testSelectors
{
   return @[
       @"testConvertDictToJSONDown",
       @"testConvertJSONtoDictUp",
       @"testConvertDictToJSONUp",
       @"testConvertJSONtoDictDown",
       @"testConvertDictToJSONDownToSource",
       @"testConvertJSONtoObjectUp",
			];
}

@end
