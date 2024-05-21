//
//  MPWMatrix.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 21.05.24.
//

#import "MPWMatrix.h"

@implementation MPWMatrix

+matrix
{
    return [[[self alloc] initIdentity] autorelease];
}

+matrixIdentity
{
    return [[[self alloc] initIdentity] autorelease];
}

-(instancetype)init
{
    return [self initIdentity];
}

-(instancetype)initIdentity
{
    self=[super initWithCount:6];
    [self clear];
    return self;
}

-(void)clear
{
    floatStart[0]=1.0;
    floatStart[1]=0.0;
    floatStart[2]=0.0;
    floatStart[3]=1.0;
    floatStart[4]=0.0;
    floatStart[5]=0.0;
    
    return ;
}
-(instancetype)initScale:(float)xScale :(float)yScale
{
    [self init];
    floatStart[0]=xScale;
    floatStart[3]=yScale;
    return self;
}


-(instancetype)initScale:(float)totalScale
{
    [self init];
    floatStart[0]=totalScale;
    floatStart[3]=totalScale;
    return self;
}


-(instancetype)initRotateRadians:(float)radians
{
    [self init];
    floatStart[0]=cos( (double)radians );
    floatStart[1]=sin( (double)radians );
    floatStart[2]=-floatStart[1];
    floatStart[3]=floatStart[0];
    return self;
}

#define    PI    3.1415926535897932384626433

-(instancetype)initRotate:(float)degrees
{
    return [self initRotateRadians:degrees * PI / 180.0];
}

-(instancetype)initTranslate:(float)tx :(float)ty
{
    [self init];
    floatStart[4]=tx;
    floatStart[5]=ty;
    return self;
}

-_concatElems:(float*)c
{
    float t[6];
    
    t[0] = floatStart[0] * c[0] + floatStart[1] * c[2];
    t[1] = floatStart[0] * c[1] + floatStart[1] * c[3];
    t[2] = floatStart[2] * c[0] + floatStart[3] * c[2];
    t[3] = floatStart[2] * c[1] + floatStart[3] * c[3];
    t[4] = floatStart[4] * c[0] + floatStart[5] * c[2]+c[4];
    t[5] = floatStart[4] * c[1] + floatStart[5] * c[3]+c[5];
    
    memcpy( floatStart, t , sizeof(float) * 6);
    return self;
}

-concat:(MPWMatrix*)otherMatrix
{
    return [self _concatElems:[otherMatrix reals]];
}

-appendTransform:otherMatrix
{
    return [self _concatElems:[otherMatrix reals]];
}


+(instancetype)matrixScale:(float)scale
{
    return [self matrixScale:scale :scale];
}

+(instancetype)matrixScale:(float)xScale :(float)yScale
{
    return  [[[self alloc] initScale:xScale :yScale] autorelease];
}

+(instancetype)matrixRotate:(float)degrees
{
    return  [[[self alloc] initRotate:degrees] autorelease];
}

+(instancetype)matrixTranslate:(float)x :(float)y;
{
    return   [[[self alloc] initTranslate:x :y] autorelease];
}


-matrixScaledBy:(float)totalScale
{
    return [[[self class] matrixScale:totalScale] concat:self];
}

-matrixScaledBy:(float)xScale y:(float)yScale
{
    return [[[self class] matrixScale:xScale :yScale] concat:self];
}

-matrixTranslatedBy:(float)xScale y:(float)yScale
{
    return [[[self class] matrixTranslate:xScale :yScale] concat:self];
}

-matrixRotatedBy:(float)degrees
{
    return [[[self class] matrixRotate:degrees] concat:self];
}

-description
{
    return [NSString stringWithFormat:@"Matrix: [ %g %g %g %g %g %g ]",
            floatStart[0],
            floatStart[1],
            floatStart[2],
            floatStart[3],
            floatStart[4],
            floatStart[5]
    ];
}


@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMatrix(testing) 

+(void)someTest
{
	EXPECTTRUE(false, @"implemented");
}

+(NSArray*)testSelectors
{
   return @[
//			@"someTest",
			];
}

@end
