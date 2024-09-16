//
//  MPWArrayCursor.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 19.10.23.
//

#import "MPWArrayCursor.h"

@interface MPWArrayCursor()

@property (nonatomic, strong) NSMutableArray *base;


@end

@implementation MPWArrayCursor
{
    long offset;
}

@dynamic offset;

-(long)offset
{
    return offset;
}

-(void)setOffset:(long)newOffset
{
    offset=newOffset;
    [self.selectionChanges writeObject:self];
}

+(instancetype)cursorWithArray:(NSMutableArray*)newarray
{
    return [[[self alloc] initWithArray:newarray] autorelease];
}

-(instancetype)initWithArray:(NSMutableArray*)newarray
{
    self=[super init];
    self.base = newarray;
    self.offset=0;
    return self;
}

-(id)value
{
    return [self.base objectAtIndex:self.offset];
}

-(void)setValue:newValue
{
    [self.base  replaceObjectAtIndex:self.offset withObject:newValue];
}

-(instancetype)copyWithZone:(NSZone*)aZone
{
    return [[[self class] allocWithZone:aZone] initWithArray:self.base];
}


-(void)dealloc
{
    [_base release];
    [super dealloc];
}

- (NSURL *)URL { 
    return nil;
}

- (id<MPWStorage>)asScheme { 
    return nil;
}

- (NSArray *)children { 
    return self.base;
}

- (void)delete { 
    [self.base removeObjectAtIndex:self.offset];
}

- (BOOL)hasChildren { 
    return YES;
}

- (instancetype)initWithIdentifer:(id)anIdentifier inStore:(id)aStore { 
    return nil;
}

+ (instancetype)referenceWithIdentifier:(id)anIdentifier inStore:(id)aStore { 
    return nil;
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWArrayCursor(testing)

+(instancetype)_testCursor
{
    NSMutableArray *testArray=[[@[ @"a", @"b"] mutableCopy] autorelease];
    MPWArrayCursor *cursor1=[self cursorWithArray:testArray];
    return cursor1;
}

+(void)testCanGetValueAtOffset
{
    MPWArrayCursor *cursor1=[self _testCursor];
    IDEXPECT( [cursor1 value], @"a", @"offset 0");
    cursor1.offset=1;
    IDEXPECT( [cursor1 value], @"b", @"offset 1");
}

+(void)testCanSetValueAtOffset
{
    MPWArrayCursor *cursor1=[self _testCursor];
    IDEXPECT( [cursor1 value], @"a", @"offset 0");
    cursor1.value = @"new value";
    IDEXPECT( cursor1.value, @"new value", @"did set");
}

+(void)testCanBeNotified
{
    MPWArrayCursor *cursor1=[self _testCursor];
    NSMutableArray *notifications=[NSMutableArray array];
    cursor1.selectionChanges=notifications;
    INTEXPECT(notifications.count,0,@"no notifications");
    cursor1.offset = 1;
    INTEXPECT(notifications.count,1,@"got a notification");

}

+(NSArray*)testSelectors
{
   return @[
       @"testCanGetValueAtOffset",
       @"testCanSetValueAtOffset",
       @"testCanBeNotified",
			];
}

@end
