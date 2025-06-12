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

-(instancetype)initWithIdentifier:(id)anIdentifier inStore:(id)aStore
{
    if(self=[super initWithIdentifier:anIdentifier inStore:aStore]) {
        offset=-1;
    }
    return self;
}


-(long)offset
{
    return offset;
}

-(void)notifyClients
{
    [self.selectionChanges writeObject:self.identifier ?: self];
    [self.modelChanges writeObject:self.identifier ?: self];
}

-(void)setOffset:(long)newOffset
{
    offset=MIN(MAX(newOffset,-1),self.base.count);      // allow -1 for "not currently set"
    [self notifyClients];
}

-(BOOL)atEnd
{
    return offset >= self.base.count-1;
}


-(void)next
{
    [self setOffset:offset+1];
}

-(void)previous
{
    [self setOffset:offset-1];
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

#define INRANGE() (offset >=0 && offset < self.base.count)

-(id)value
{
    return INRANGE() ? [self.base objectAtIndex:offset] : nil;
}

-(void)setValue:newValue
{
    if ( INRANGE() ) {
        [self.base  replaceObjectAtIndex:offset withObject:newValue];
    }
}

-(BOOL)isBound
{
    return INRANGE();
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
    NSMutableArray *selectionNotifications=[NSMutableArray array];
    NSMutableArray *modelfNotifications=[NSMutableArray array];
    cursor1.selectionChanges=selectionNotifications;
    INTEXPECT(selectionNotifications.count,0,@"no notifications");
    cursor1.offset = 1;
    INTEXPECT(selectionNotifications.count,1,@"got a notification");
    cursor1.modelChanges=modelfNotifications;
    INTEXPECT(modelfNotifications.count,0,@"no notifications");
    cursor1.offset = 0;
    INTEXPECT(modelfNotifications.count,1,@"got a notification");

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
