//
//  MPWInterval.m
//  MPWTalk
//
//  Created by Marcel Weiher on 26/11/2004.
//  Copyright 2004 Marcel Weiher. All rights reserved.
//

#import "MPWInterval.h"
//#import <MPWFoundation/MPWFoundation.h>
#import <MPWWriteStream.h>
#import "NSNumberArithmetic.h"
#import "MPWIntArray.h"
#import "CodingAdditions.h"
#import "NSObjectFiltering.h"
#include <pthread.h>

@interface NSObject(value)
-value:arg;
@end

@interface MPWIntervalEnumerator : MPWLongInterval
{
    long current;
}

longAccessor_h( current, setCurrent )
-initWithInterval:(MPWInterval*)interval;
+enumeratorWithInterval:(MPWInterval*)interval;
-nextObject;


@end

@implementation MPWInterval


#define FROM	range.location

#define INTATINDEX( anIndex )   ((FROM + (anIndex))*_step)
#define TO		((range.location + range.length-1))

-(long)step
{
    return 1;
}


//scalarAccessor( int, from, setFrom )
//scalarAccessor( int, to, setTo )

-(void)setStep:(long)newVar
{
	if ( newVar <= 0 ) {
		@throw [NSException
				exceptionWithName:@"InvalidArgument"
				reason:[NSString stringWithFormat:@"-[%@ setStep:%ld] must be >=1",[self class],newVar]
				userInfo:nil];
		
	}
	[self _setStep:newVar];
}


scalarAccessor( Class, numberClass ,_setNumberClass )

-(void)setNumberClass:(Class)newClass
{
    static id avoid=nil;
    static id replace=nil;
    if (!avoid) {
        avoid=NSClassFromString(@"__NSCFNumber");
        replace=[NSNumber class];
    }
    if (newClass==avoid) {
        newClass=replace;
    }
    [self _setNumberClass:newClass];
}

+intervalFrom:newFrom to:newTo 
{
	return [[[self alloc] initFrom:newFrom to:newTo ] autorelease];
}


+intervalFrom:newFrom to:newTo step:newStep
{
	return [[[self alloc] initFrom:newFrom to:newTo step:newStep] autorelease];
}



+intervalFromInt:(long)newFrom toInt:(long)newTo step:(long)newStep
{
	return [[[MPWLongInterval alloc] initFromInt:newFrom toInt:newTo step:newStep numberClass:[NSNumber class]] autorelease];
}

+intervalFromInt:(long)newFrom toInt:(long)newTo
{
    return [self intervalFromInt:newFrom toInt:newTo step:1];
}



-collect:aBlock
{
	return [self do:aBlock with:[NSMutableArray array]];
}

-(void)do:aBlock
{
	[self do:aBlock with:nil];
}

-(BOOL)containsObject:anObject
{
    return  [anObject respondsToSelector:@selector(intValue)] &&
            [self containsInteger:[anObject intValue]];
}

-objectEnumerator
{
    return [MPWIntervalEnumerator enumeratorWithInterval:self];
}

-each
{
    return [self objectEnumerator];
}


-(void)writeOnShellPrinter:aPrinter
{
    [aPrinter writeObject:[self description]];
}


-(void)writeOnStream:aStream
{
    [aStream writeEnumerator:self];
}

@end

@implementation MPWDoubleInterval
{
    double from,to,step;
}

+(instancetype)intervalFromDouble:(double)newFrom toDouble:(double)newTo
{
    return [[[self alloc] initFromDouble:newFrom toDouble:newTo step:1.0 numberClass:[NSNumber class]] autorelease];
}


-(instancetype)initFromDouble:(double)newFrom toDouble:(double)newTo step:(double)newStep numberClass:(Class)newNumberClass
{
    if (self=[super init] ) {
        from=newFrom;
        to=newTo;
        step=newStep;
    }
    return self;
}

scalarAccessor( double, from, setFrom )
scalarAccessor( double, to, setTo )
scalarAccessor( double, step, setStep )

-(instancetype)initFrom:newFrom to:newTo step:newStep
{
    return [self initFromDouble:[newFrom doubleValue] toDouble:[newTo doubleValue] step:[newStep doubleValue] numberClass:[newFrom class]];
}

-(instancetype)initFrom:newFrom to:newTo
{
    return [self initFromDouble:[newFrom intValue] toDouble:[newTo intValue] step:1.0 numberClass:[newFrom class]];
}

-(NSNumber*)random
{
    double weight=drand48();
    return [NSNumber numberWithDouble:from * weight + (1-weight) * to];
}

-description
{
    return [NSString stringWithFormat:@"<%@:%p from %g to %g>",[self class],self,[self from],[self to]];
}


@end

@implementation MPWLongInterval


-initFromInt:(long)newFrom toInt:(long)newTo step:(long)newStep numberClass:(Class)newNumberClass
{
    self=[super init];
    [self setFrom:newFrom];
    [self setTo:newTo];
    [self setStep:newStep];
    [self setNumberClass:newNumberClass];
    return self;
}

-initFromInt:(long)newFrom toInt:(long)newTo  numberClass:(Class)newNumberClass
{
    return [self initFromInt:newFrom toInt:newTo step:1 numberClass:newNumberClass];
}


-initFromInt:(long)newFrom toInt:(long)newTo
{
    return [self initFromInt:newFrom toInt:newTo numberClass:[NSNumber class]];
}



-initFrom:newFrom to:newTo step:newStep
{
    return [self initFromInt:[newFrom intValue] toInt:[newTo intValue] step:[newStep intValue] numberClass:[newFrom class]];
}

-initFrom:newFrom to:newTo
{
    return [self initFromInt:[newFrom intValue] toInt:[newTo intValue] step:1 numberClass:[newFrom class]];
}


-(long)from {  return FROM; }
-(long)to   {  return TO; }
-(void)setFrom:(long)newFrom { range.location=newFrom; }
-(void)setTo:(long)newTo { range.length = newTo - range.location + 1; }

-asArray
{
    return [[[MPWIntArray alloc] initFromInt:range.location toInt:range.location+range.length step:_step] autorelease];
}


-(NSRange)asNSRange {
    return range;
}

-(NSRange)rangeValue {
    return range;
}

-(NSRangePointer)rangePointer {
    return &range;
}

#define defineArithOp( opName , adjustStep ) \
-(id)opName:other {\
NSNumber *from1=[@(FROM) opName: other];\
NSNumber *to1=[@(TO) opName: other];\
NSNumber *step1=@([self step]);\
if ( adjustStep ) { \
step1 = [step1 opName: other]; \
} \
MPWInterval *newInterval=[[self class] intervalFrom:from1 to:to1 step:step1];\
return newInterval;\
}\


defineArithOp( add, false )
defineArithOp( mul, true)
defineArithOp( sub, false)
defineArithOp( div, true )


-(NSNumber*)random
{
    double weight=drand48();
    return [NSNumber numberWithInt:[self from] * weight + (1-weight) * [self to]];
}
-(NSUInteger)count
{
    return range.length / _step;
}

-(long)integerAtIndex:(NSUInteger)anIndex
{
    if ( anIndex >= [self count] ) {
        @throw [NSException
                exceptionWithName:@"RangeException"
                reason:[NSString stringWithFormat:@"-[%@ integerAtIndex:%ld] out of bounds(%ld)",[self class],(long)anIndex,(long)[self count]]
                userInfo:nil];
    }
    return INTATINDEX( anIndex );
}

-(BOOL)containsInteger:(int)anInt
{
    return FROM <= anInt && anInt <= TO;
}

-objectAtIndex:(NSUInteger)anIndex
{
    return [numberClass numberWithLong:[self integerAtIndex:anIndex]];
}

-description
{
    return [NSString stringWithFormat:@"<%@:%p from %ld to %ld>",[self class],self,[self from],[self to]];
}


-do:aBlock with:target
{
    id value=nil;
    for (long i=FROM;i<=TO;i+=_step ) {
        @autoreleasepool {
            value = [aBlock value:[numberClass numberWithLong:i]];
            [target addObject:value];
        }
    }
    return target ? target : value;
}

static void* runBlock( void *blockAndArgAsVoid ){
    NSArray* blockAndArg=(NSArray*)blockAndArgAsVoid;
    @autoreleasepool {
        [blockAndArg[0] value:blockAndArg[1]];
    }
    [blockAndArg release];
    pthread_exit(NULL);
    return NULL;
}

-(void)pthreads:aBlock
{
    long maxThreads=(TO+1-FROM)/_step;
    pthread_t threads[maxThreads + 10];
    int numThreads=0;
    for (long i=FROM;i<=TO;i+=_step ) {
        
        @autoreleasepool {
            pthread_create(threads+numThreads++, NULL, runBlock, [@[ aBlock, @(i)] retain]);
        }
    }
    for (int i=0;i<numThreads;i++) {
        pthread_join( threads[i], NULL );
    }
}


-(void)parallel_group:workBlock
{
    dispatch_group_t aGroup = dispatch_group_create();
    //    VoidBlock aBlock = ^{
    //        [workBlock value];
    //        dispatch_group_leave(aGroup);
    //    };
    for (long i=FROM;i<=TO;i+=_step ) {
        dispatch_group_enter(aGroup);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [workBlock value:@(i)];
            dispatch_group_leave(aGroup);
        });
    }
    dispatch_group_wait(aGroup, DISPATCH_TIME_FOREVER);
}

-(void)parallel:workBlock
{
    dispatch_apply((TO+1-FROM)/_step, dispatch_get_global_queue(0, 0), ^(size_t i){
        [workBlock value:@(FROM+i*_step)];
    });
}

@end

@implementation NSArray(parallel)

-(void)parallel
{
    dispatch_apply(self.count, dispatch_get_global_queue(0, 0), ^(size_t i){
        [self[i] value];
    });
}


@end




@implementation NSNumber(intervals)


-to:other
{
    const char *type1s=[self objCType];
    const char *type2s=[other objCType];
    
    if ( type1s && type2s ) {
        char type1=*type1s;
        char type2=*type2s;
        if ( (type1=='i' || type1=='q' ) && (type2=='i' || type2=='q' ) ) {
            return [MPWLongInterval intervalFromInt:[self intValue] toInt:[other intValue]];
        } else {
            return [MPWDoubleInterval intervalFromDouble:[self doubleValue] toDouble:[other doubleValue]];
        }
    }
    return nil;
}


-to:otherNumber by:stepNumber
{
    return [MPWInterval intervalFrom:self to:otherNumber step:stepNumber];
}

-max:otherNumber
{
    if ( [self doubleValue] < [otherNumber doubleValue] ) {
        return otherNumber;
    } else {
        return self;
    }
}


-min:otherNumber
{
    if ( [self doubleValue] > [otherNumber doubleValue] ) {
        return otherNumber;
    } else {
        return self;
    }
}

-(void)do:aBlock
{
    [[@(0) to:[self sub:@(1)]] do:aBlock];
}


-(void)repeat:aBlock
{
    [self do:aBlock];
}


@end


#import "DebugMacros.h"

@implementation MPWInterval(testing)

+(void)testBasicInterval
{
	MPWLongInterval *one_to_ten=[MPWLongInterval intervalFromInt:1 toInt:10];
	INTEXPECT( [one_to_ten integerAtIndex:0], 1, @"first of [1-10]");
	INTEXPECT( [one_to_ten integerAtIndex:1], 2, @"second of [1-10]");
	INTEXPECT( [one_to_ten integerAtIndex:9], 10, @"last of [1-10]");
}

+(void)testIntervalRespectsRange
{
	MPWInterval *one_to_ten=[MPWLongInterval intervalFromInt:1 toInt:10];
	BOOL failedToRaise=NO;
	@try {
		[one_to_ten integerAtIndex:10];
		failedToRaise=YES;
	}
	@catch (NSException * e) {
	}
	EXPECTFALSE( failedToRaise, @"failedToRaise");
}

+(void)testIntervalWithStep
{
	MPWInterval *one_to_ten=[MPWLongInterval intervalFromInt:1 toInt:10 step:2];
	INTEXPECT( [one_to_ten count] ,5, @"count");
	INTEXPECT( [one_to_ten integerAtIndex:0], 2, @"first of [1-10]");
	INTEXPECT( [one_to_ten integerAtIndex:1], 4, @"second of [1-10]");
	INTEXPECT( [one_to_ten integerAtIndex:4], 10, @"last of [1-10]");
}

+(void)testIntervalArithmetic
{
    MPWInterval *five_to_ten=[MPWLongInterval intervalFromInt:4 toInt:10];
    INTEXPECT( [[five_to_ten add:@2] from], 6, @"add 2 to interval -> from");
    INTEXPECT( [[five_to_ten add:@2] to], 12, @"add 2 to interval -> to");
    INTEXPECT( [[five_to_ten mul:@3] from], 12, @"mul interval by 3 -> from");
    INTEXPECT( [[five_to_ten mul:@3] to], 30, @"mul interval by 3 -> to");
    INTEXPECT( [[five_to_ten sub:@3] from], 1, @"sub 3 from interval -> from");
    INTEXPECT( [[five_to_ten sub:@3] to], 7, @"sub 3 from interval -> to");
}

+(void)testNumberIntervalConveniences
{
    IDEXPECT( ([@(1) to:@(10)]), [MPWInterval intervalFromInt:1 toInt:10], @"to: on number");
}

+(void)testNumberIntervalConveniencesWithLongs
{
    IDEXPECT( ([[NSNumber numberWithLong:1] to:@(10)]), [MPWInterval intervalFromInt:1 toInt:10], @"to: on number");
}

+(void)testIntervalCollect
{
#ifndef GS_API_LATEST
    IDEXPECT( ([@(3) collect:^id (id i){ return i;} ]), (@[@(0),@(1),@(2)]), @"collect: on number" );
#else
#warning MPWInterval collect doesn't work on gnustep
#endif
}

+testSelectors
{
    return [NSArray arrayWithObjects:
			@"testBasicInterval",
			@"testIntervalRespectsRange",
            @"testIntervalWithStep",
            @"testIntervalArithmetic",
            @"testNumberIntervalConveniencesWithLongs",
            @"testNumberIntervalConveniences",
            @"testIntervalCollect",
        nil];
}

@end

@implementation MPWIntervalEnumerator

longAccessor( current, setCurrent )

-initFromInt:(long)newFrom toInt:(long)newTo
{
    self=[super initFromInt:newFrom toInt:newTo];
    [self setCurrent:newFrom];
    return self;
}

-initWithInterval:(MPWInterval*)interval
{
    self=[super init];
    [self setFrom:[interval from]];
    [self setTo:[interval to]];
    [self setStep:[interval step]];
    [self setCurrent:[self from]];
    [self setNumberClass:[interval numberClass]];
    return self;
}
+enumeratorWithInterval:(MPWInterval*)interval
{
    return [[[self alloc] initWithInterval:interval] autorelease];
}

-(BOOL)isAtEnd
{
    return current > TO;
}

-nextObject
{
    id retval=nil;
    if ( ![self isAtEnd] ) {
        retval=[numberClass numberWithLong:current];
        current+=self.step;
    }
    return retval;
}

-objectEnumerator
{
    return self;
}


@end

@implementation NSArray(iteration)

-do:aBlock with:target
{
    id value=nil;
    for (long i=0,max=[self count];i<max;i++ ) {
        value = [aBlock value:[self objectAtIndex:i]];
        [target addObject:value];
    }
    return target ? target : value;
}

-select:aBlock with:target
{
    id value=nil;
    for (long i=0,max=[self count];i<max;i++ ) {
        id obj=[self objectAtIndex:i];
        value = [aBlock value:obj];
        if ([value intValue]) {
            [target addObject:obj];
        }
    }
    return target;
}

-select:aBlock
{
    return [self select:aBlock with:[NSMutableArray array]];
}

-collect:aBlock
{
	return [self do:aBlock with:[NSMutableArray array]];
}

-do:aBlock
{
	return [self do:aBlock with:nil];
}

-sum {
    return [[self reduce] add:@(0)];
}

@end

