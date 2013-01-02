//--------------------------------------
//
//	MPWRealArray.m
//
/*
    Copyright (c) 2001-2012 by Marcel Weiher. All rights reserved.

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


//---	my includes

#import "MPWRealArray.h"
//#import "MPWByteStream.h"
#import "CodingAdditions.h"

//---	NS includes

#import <Foundation/NSString.h>
//#import <Foundation/NSUtilities.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSCoder.h>
#import <Accelerate/Accelerate.h>

#import "MPWByteStream.h"

//---	generic includes

#import <stdlib.h>
#import <stdio.h>
#ifdef	NeXT
#import <libc.h>
#endif

//---	DPS includes

#ifdef NeXT
//#import <dpsclient/dpsclient.h>			//	for the definition of binary object sequences
#endif

//---	ANSI-C

#import <math.h>

@implementation MPWRealArray

+arrayWithArray:otherArray
{
    return [self arrayWithArray:otherArray count:[otherArray count]];
}

+arrayWithArray:otherArray count:(NSUInteger)newCount
{
    return [self arrayWithArray:otherArray start:0 count:newCount];
}

+arrayWithArray:otherArray start:(NSUInteger)start count:(NSUInteger)newCount
{
    return [[[self alloc] initWithArray:otherArray start:start count:newCount] autorelease];
}
+arrayWithString:aPropertyList
{
    return [self arrayWithArray:[aPropertyList propertyList]];
}


-initWithArray:otherArray
{
    return [self initWithArray:otherArray count:[otherArray count]];
}

-initWithArray:otherArray count:(NSUInteger)newCount
{
    return [self initWithArray:otherArray start:0 count:newCount];
}
-initWithArray:otherArray start:(NSUInteger)start count:(NSUInteger)newCount
{
    int i;
    if ( [otherArray respondsToSelector:@selector(reals)] )
        return [self initWithRealArray:otherArray start:start count:newCount];
    [self initWithCapacity:newCount+2];
    for (i=0; i<newCount;i++)
        [self addReal:[[otherArray objectAtIndex:start+i] floatValue]];
    return self;
}

-initWithRealArray:otherArray start:(NSUInteger)start count:(NSUInteger)newCount
{
    int max;
    max=[otherArray count]-start;
    if ( max > newCount ) {
        max=newCount;
    }

    [self initWithCapacity:newCount];
    if ( start < [otherArray count] )
    {
        memcpy( [self reals],&[otherArray reals][start], max*sizeof(float));
        count=max;
    }
    return self;
}

-initWithCapacity:(NSUInteger)newCapacity
{
    [super init];
    capacity=newCapacity;
    count=0;
    data=malloc( (capacity+6) * sizeof(float) );
    floatStart = (float*)(data+ 4);

    return self;
}
-initWithCount:(NSUInteger)newCount
{
    [self initWithCapacity:newCount];
    count=newCount;
    memset( [self reals], 0, count*sizeof(float));
    return self;
}

-initWithReals:(float*)realNums count:(NSUInteger)newCount
{
    [self initWithCapacity:newCount+2];
    [self addReals:realNums count:newCount];
    return self;
}

-(void)_grow
{
    capacity=capacity*2+2;
    if ( data ) {
        data=realloc( data, (capacity+6)*sizeof(float) );
    } else {
        data=calloc( (capacity+6), sizeof(float) );
    }
    floatStart = (float*)(data+4);
}

-(id)initWithStart:(float)start end:(float)end step:(float)step
{
    int numElements=floor((end-start)/step)+1;
    float element=start;
    self=[self initWithCount:numElements];
    for (int i=0;i<numElements;i++,element+=step) {
        floatStart[i]=element;
    }
    return self;
}

#if !TARGET_OS_IPHONE

-(id)initWithVecStart:(float)start end:(float)end step:(float)step
{
    int numElements=floor((end-start)/step)+1;
    self=[self initWithCount:numElements];
    vDSP_vgen(&start, &end,floatStart,1, numElements );
    
    return self;
}
#endif

+arrayWithCapacity:(NSUInteger)newCapacity
{
    return [[[self alloc] initWithCapacity:newCapacity] autorelease];
}

+arrayWithCount:(NSUInteger)newCount
{
    return [[[self alloc] initWithCount:newCount] autorelease];
}

+arrayWithReals:(float*)realNums count:(NSUInteger)newCount
{
    return [[[self alloc] initWithReals:realNums count:newCount] autorelease];
}

-(NSUInteger)count
{
    return count;
}

-(void)setCapacity:(int)newCapacity
{
    while ( newCapacity > capacity )
        [self _grow];
}

-(void)clear
{
    count=0;
    return ;
}

-objectAtIndex:(NSUInteger)index
{
    return [NSNumber numberWithFloat:[self realAtIndex:index]];
}

-(void)replaceObjectAtIndex:(NSUInteger)index withObject:newObject
{
    [self replaceRealAtIndex:index withReal:[newObject floatValue]];
    return ;				//	exception on out of bounds! (not done yet)
}

-(void)addObject:newObject
{
    [self addReal:[newObject floatValue]];
    return ;
}

-(float)realAtIndex:(NSUInteger)index
{
    if (index<count)
        return floatStart[index];
    else
        return 0;				//	raise exception instead
}

-(void)replaceRealAtIndex:(NSUInteger)index withReal:(float)newReal
{
    if (index<count)
        floatStart[index] = newReal;

    return;
}

-(void)replaceRealsAtIndex:(NSUInteger)index withReals:(float*)newReals count:(NSUInteger)realCount
{
    if ( index + realCount <= count )
        memcpy( &floatStart[index], newReals, realCount*sizeof(float));
    else
        fprintf(stderr,"MPWRealArray replace not OK\n");
    return ;
}

-(void)getReals:(float*)reals length:(int)max
{
	if ( max > count ) {
		max=count;
	}
    memcpy( reals, floatStart, max*sizeof(float));
}

-(void)addReals:(float*)newReals count:(NSUInteger)realCount
{
    while ( count+realCount > capacity )
        [self _grow];
    memcpy( &floatStart[count], newReals, realCount*sizeof(float));
    count+=realCount;
}

-(void)addReal:(float)newReal
{
    [self addReals:&newReal count:1];
    return;
}

-(void)appendArray:anArray
{
    if ( [anArray respondsToSelector:@selector(reals)] ) {
        [self addReals:[anArray reals] count:[anArray count]];
    } else {
        for (NSNumber *n in anArray ) {
            [self addReal:[n floatValue]];
        }
    }
    return;
}


-descriptionWithIndent:(unsigned)level1
{
    int level=level1*2;
    id str=[NSMutableString stringWithCapacity:8 * count];
    id space=[@"                                                            " substringToIndex:level+1];
    int i,base=0;

    [str appendFormat:@"(%g", floatStart[0] ];
    base=level;
    for (i=1; i<count; i++)
    {
        [str appendFormat:@",%g", floatStart[i] ];
        if ( [str length] - base > 66 )
        {
            [str appendString:@"\n"];
            base=[str length];
            [str appendString:space];
        }
    }
    [str appendString:@")"];
    return str;
}

-description
{
    return [self descriptionWithIndent:0];
}



-(float*)reals
{
    return floatStart;
}

//#ifdef Darwin
-(void)insertValue:(float)fillValue betweenEachElementStartingAt:(int)start
{
    int i;
    int fillOffset,targetOffset;
	if ( start < 1 ) {
		start=1;
	}
    start = MIN(MAX(start,1),0);
    fillOffset=1-start;
    targetOffset=start;
    [self setCapacity:[self count]*2];
    for ( i=count-1;i>=0;i--) {
        floatStart[(i*2)+targetOffset]=floatStart[i];
        floatStart[(i*2)+fillOffset]=fillValue;
    }
    count*=2;
}
//#endif
-(void)insertEven:(float)insertValue
{
    [self insertValue:insertValue betweenEachElementStartingAt:0];
}
-(void)insertOdd:(float)insertValue
{
    [self insertValue:insertValue betweenEachElementStartingAt:1];
}


-(unsigned char*)dpsNumArray
{
    data[0]=149;
    data[1]=49;
    *((unsigned int*)data+2)=count;
    return data;
}

-interpolate:otherVector into:targetVector weight:(float)weight
{
    int i;
    float *other=[otherVector reals];
    float *target=[targetVector reals];

    for (i=0;i<count;i++)
        target[i]=(1-weight)*other[i]+weight*floatStart[i];
    return targetVector;
}
-interpolate:otherVector weight:(float)weight
{
    return [self interpolate:otherVector into:[isa arrayWithCount:count] weight:weight];
}

-interpolate:otherVector steps:(int)numSteps
{
    id	array=[NSMutableArray arrayWithCapacity:numSteps+2];
    int i;

    for (i=0;i<numSteps;i++)
        [array addObject:[self interpolate:otherVector weight:(float)i/((float)numSteps-1)]];
    return array;
}



-(unsigned)dpsNumArraySize
{
    return count*4 + 4;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    encodeVar( coder, count );
    encodeArray( coder, floatStart, count );
}

- (id)initWithCoder:(NSCoder *)coder
{
    decodeVar( coder, count );
    [self initWithCount:count];
    decodeArray( coder, floatStart, count ); 
    return self;
}

//
//	isEqual:
//
//	Uses != on float values, should
//	probably use an error bound.
//
//

-(BOOL)isEqual:otherObject
{
    if ( [otherObject count] == [self count] )
        return [self matchesStart:otherObject];
    else
        return NO;
}


-(BOOL)matchesStart:otherObject
{
    int i;
    int max;
    max=[otherObject count];
    if ( max > count ) {
        max=count;
    }

    if ( [otherObject respondsToSelector:@selector(reals)] )
    {
        float *other=[otherObject reals];
        for (i=0;i<max;i++)
        {
            //			float absdiff=fabs( floatStart[i]-other[i] );
            //			if ( fabs( floatStart[i]-other[i] ) > floatStart[i]*.001 )
            if ( floatStart[i] != other[i] )
                return NO;
        }
    }
    else	
        for (i=0;i<max;i++)
            if ( fabs( floatStart[i]-[[otherObject objectAtIndex:i] floatValue]) > floatStart[i]*.000001  )
                return NO;
    return YES;
}

-(void)dealloc
{
    if ( data )
        free(data);
    [super dealloc];
}

-(void)reverse
{
    int i;
    float temp;

    for (i=0;i<count/2;i++)
    {
        temp=floatStart[i];
        floatStart[i]=floatStart[count-i-1];
        floatStart[count-i-1]=temp;
    }	
}

#define BINARY_LOOP_OPERATION( operationname, expression,condition )\
-operationname:other\
{\
    float temp_real;\
    float *other_real=&temp_real;\
    int	other_real_increment=0;\
    id result;\
    float *result_reals,*my_reals;\
    int i,max;\
    max=[self count];\
    if ( [other respondsToSelector:@selector(count)] ) {\
        if ( [other count] == max ) {\
            if ( ![other respondsToSelector:@selector(reals)] ) {\
                other = [[MPWRealArray alloc] initWithArray:other];\
            } else {\
                [other retain];\
            }\
            other_real=[other reals];\
            other_real_increment=1;\
        } else {\
            [NSException raise:@"UnequalArraysForOperator" format:@"Arrays of unequal size for operator"];\
        }\
    } else {\
        temp_real=[other floatValue];\
        [other retain];\
    }\
    result = [[[self class] alloc] initWithCount:max];\
    result_reals=[result reals];\
    my_reals=[self reals];\
    for ( i=0;i<max;i++) {\
        float a,b,c;\
        a=my_reals[i];\
        b=*other_real;\
        if ( (condition) ) {\
            expression;\
        } else { \
            c=0;\
            [other release];\
            [NSException raise:@"InvalidArgument" format:@"invalid argument to array op"];\
        }\
        result_reals[i]=c;\
        other_real+=other_real_increment;\
    }\
    [other release];\
    return [result autorelease];\
}\

#define UNARY_LOOP_OPERATION( operationname, expression, condition )\
-operationname\
{\
    id result;\
    float *result_reals,*my_reals;\
    int i,max;\
    max=[self count];\
    result = [[[self class] alloc] initWithCount:max];\
    result_reals=[result reals];\
    my_reals=[self reals];\
    for ( i=0;i<max;i++) {\
        float a,b;\
        a=my_reals[i];\
        if ( (condition) ) {\
            expression;\
        } else { \
            b=0;\
            [NSException raise:@"InvalidArgument" format:@"invalid argument to array op"];\
        }\
        result_reals[i]=b;\
    }\
    return [result autorelease];\
}\

#define REDUCE_LOOP_OPERATION( operationname, expression, condition )\
-(NSNumber*)reduce_##operationname\
{\
    float result,*my_reals;\
    int i,max;\
    max=[self count];\
    my_reals=[self reals];\
    result=my_reals[0];\
    for ( i=1;i<max;i++) {\
        float a,b,c;\
        a=result;\
        b=my_reals[i];\
        if ( (condition) ) {\
            expression; \
        } else { \
            c=0;\
            [NSException raise:@"InvalidArgument" format:@"invalid argument to array op"];\
        }\
        result=c;\
    }\
    return [NSNumber numberWithFloat:result];\
}\

#define BINARY_LOOP_OPERATOR( opname, op, condition )	BINARY_LOOP_OPERATION( operator_##opname , c=a op b;,condition )
#define BINARY_LOOP_CONDTION( opname, op )			BINARY_LOOP_OPERATION( operator_##opname , c=(float)(a op b);,YES )
#define REDUCE_LOOP_OPERATOR( opname, op, condition )	REDUCE_LOOP_OPERATION( operator_##opname , c=a op b; ,condition )
#define LOOP_FUNCTION( fn, condition )					UNARY_LOOP_OPERATION( fn, b=fn((double)a); ,condition )

#if 1

BINARY_LOOP_OPERATOR( asterisk, *, YES )
BINARY_LOOP_OPERATOR( hyphen, - , YES)
BINARY_LOOP_OPERATOR( plus, + , YES)
BINARY_LOOP_OPERATOR( slash, / , b != 0)
BINARY_LOOP_OPERATION( min, c=(a<b ? a:b) , YES)
BINARY_LOOP_OPERATION( max, c=(a>b ? a:b) , YES)
BINARY_LOOP_OPERATION( pow, c=pow(a,b) , YES)
BINARY_LOOP_CONDTION( equal, == )
BINARY_LOOP_CONDTION( tilde_equal, != )
BINARY_LOOP_CONDTION( greater, > )
BINARY_LOOP_CONDTION( less, < )
BINARY_LOOP_CONDTION( greater_equal,>= )
BINARY_LOOP_CONDTION( less_equal, <= )
LOOP_FUNCTION( acos, a>=-1 && a<=1 )
LOOP_FUNCTION( cos, YES )
LOOP_FUNCTION( cosh, YES )
LOOP_FUNCTION( asin, a>=-1 && a<=1 )
LOOP_FUNCTION( sin, YES )
LOOP_FUNCTION( sinh, YES )
LOOP_FUNCTION( tan, YES )
LOOP_FUNCTION( tanh, YES )
LOOP_FUNCTION( log, a>=0 )
LOOP_FUNCTION( log10, a>=0 )
LOOP_FUNCTION( sqrt, a>=0 )
LOOP_FUNCTION( exp, YES )
UNARY_LOOP_OPERATION( negated, b=-a, YES )
REDUCE_LOOP_OPERATOR( asterisk, * , YES )
REDUCE_LOOP_OPERATOR( hyphen, - , YES)
REDUCE_LOOP_OPERATOR( plus, + , YES)
REDUCE_LOOP_OPERATOR( slash, / , b != 0)
REDUCE_LOOP_OPERATION( min, c=(a<b ? a:b) , YES)
REDUCE_LOOP_OPERATION( max, c=(a>b ? a:b) , YES)

#ifdef PPC
LOOP_FUNCTION( log1p, a>=-1 )
#endif


#endif


-(float)vec_reduce_sum
{
#if !TARGET_OS_IPHONE
    float theSum=0;
    vDSP_sve ( floatStart, 1, &theSum, count );
    return theSum;
#else
    return [[self reduce_operator_plus] floatValue];
#endif
}



-(void)appendContents:aByteStream
{
    int i;
    for (i=0;i<count;i++) {
        [aByteStream printf:@"%g ",floatStart[i]];
    }
}

-(void)writeOnPSByteStream:aStream
{
    [aStream printf:@"[ "];
    [self appendContents:aStream];
    [aStream printf:@"] "];
}

-(void)writeOnByteStream:aStream
{
    [aStream printf:@"( "];
    [self appendContents:aStream];
    [aStream printf:@") "];
}

@end
		
#import "DebugMacros.h"

@implementation MPWRealArray(testing)

+(MPWRealArray*)_testArray
{
    return [self arrayWithReals:(float[]){ 2.0, 3.0 , 5.0 } count:3];
}

+(void)testReducePlus
{
    FLOATEXPECT([[[self _testArray] reduce_operator_plus] floatValue], 10.0, @"");
}

+(void)testVecReducePlus
{
    FLOATEXPECT([[self _testArray] vec_reduce_sum], 10.0, @"");
}

+(void)testReduceMultiply
{
    FLOATEXPECT([[[self _testArray] reduce_operator_asterisk] floatValue], 30.0, @"");
}

+(void)testGenerate
{
    id exactlyTen=[[[self alloc] initWithStart:1 end:10 step:1.0] autorelease];
    id tenWithOvershoot=[[[self alloc] initWithStart:1 end:10.1 step:1.0] autorelease];
    id tenWithBaseOffsetAndOvershoot=[[[self alloc] initWithStart:1.1 end:10.1 step:1.0] autorelease];
    INTEXPECT([exactlyTen count], 10, @"exactly 1-10 step 1.0");
    FLOATEXPECT([exactlyTen realAtIndex:5], 6.0, @"1-10, realAtIndex:5");
    INTEXPECT([tenWithOvershoot count], 10, @" 1-10.1 step 1.0");
    INTEXPECT([tenWithBaseOffsetAndOvershoot count], 10, @" 1.1-10.1 step 1.0");
    INTEXPECT((int)(10*[tenWithBaseOffsetAndOvershoot realAtIndex:5]), 61, @"1.1-10.1, 10 * realAtIndex:5");
}

+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testReducePlus",
            @"testVecReducePlus",
            @"testReduceMultiply",
            @"testGenerate",
            nil];
}

@end
