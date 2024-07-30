//
//  MPWCursor.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.10.23.
//

#import "MPWCursor.h"

@interface MPWCursor()

@property (nonatomic, strong) MPWReference *base;
@property (nonatomic, assign) long offset;


@end

@implementation MPWCursor

-(instancetype)initWithBinding:(MPWReference*)aBinding offset:(long)newOffset
{
    self=[super init];
    self.base=aBinding;
    self.offset=newOffset;
    return self;
}

+(instancetype)cursorWithBinding:aBinding offset:(long)newOffset
{
    return [[[self alloc] initWithBinding:aBinding offset:newOffset] autorelease];
}

-(id)value
{
    return [(NSArray*)self.base.value objectAtIndex:self.offset];
}

-(void)setValue:newValue
{
    [(NSMutableArray*)self.base.value  replaceObjectAtIndex:self.offset withObject:newValue];
}

-(instancetype)copyWithZone:(NSZone*)aZone
{
    return [[[self class] allocWithZone:aZone] initWithBinding:self.base offset:self.offset];
}


-(void)dealloc
{
    [_base release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWCursor(testing) 

+(void)testCanGetValueAtTheInitialisedOffset
{
    NSArray *testArray=@[ @"a", @"b"];
    MPWDictStore *store=[MPWDictStore store];
    store[@"array"]=testArray;
    MPWReference *base=[store bindingForReference:@"array" inContext:nil];
    IDEXPECT( [base value], testArray, @"base binding works");
    MPWCursor *cursor1=[self cursorWithBinding:base offset:0];
    IDEXPECT( [cursor1 value], @"a", @"offset 0");
    MPWCursor *cursor2=[self cursorWithBinding:base offset:1];
    IDEXPECT( [cursor2 value], @"b", @"offset 1");
}

+(void)testCanSetValueAtTheInitialisedOffset
{
    NSArray *testArray=[[@[ @"a", @"b"] mutableCopy] autorelease];
    MPWDictStore *store=[MPWDictStore store];
    store[@"array"]=testArray;
    MPWReference *base=[store bindingForReference:@"array" inContext:nil];
    MPWCursor *cursor1=[self cursorWithBinding:base offset:0];
    IDEXPECT( [cursor1 value], @"a", @"offset 0");
    cursor1.value = @"new value";
    IDEXPECT( [testArray firstObject], @"new value", @"did set");
}

+(NSArray*)testSelectors
{
   return @[
       @"testCanGetValueAtTheInitialisedOffset",
       @"testCanSetValueAtTheInitialisedOffset",
			];
}

@end
