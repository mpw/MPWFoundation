//
//  MPWMatrix.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 21.05.24.
//

#import <MPWFoundation/MPWFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPWMatrix : MPWRealArray

+(instancetype)matrix;
+(instancetype)matrixIdentity;
+(instancetype)matrixScale:(float)scaleFactor;
+(instancetype)matrixScale:(float)xScale :(float)yScale;
+(instancetype)matrixTranslate:(float)x :(float)y;
+(instancetype)matrixRotate:(float)degrees;

-(instancetype)initIdentity;
-(instancetype)initScale:(float)xScale :(float)yScale;
-(instancetype)initScale:(float)totalScale;
-(instancetype)initRotate:(float)degrees;
-(instancetype)initTranslate:(float)tx :(float)ty;


-(instancetype)matrixScaledBy:(float)totalScale;
-(instancetype)matrixScaledBy:(float)xScale y:(float)yScale;
-(instancetype)matrixTranslatedBy:(float)xScale y:(float)yScale;
-(instancetype)matrixRotatedBy:(float)degrees;

-(instancetype)concat:(MPWMatrix*)otherMatrix;

@end

NS_ASSUME_NONNULL_END
