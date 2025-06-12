//
//  NSNumberArithmetic.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/3/07.
//  Copyright 2007 by Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>


NSNumber* MPWCreateInteger( long theInteger );

@interface NSNumber(Arithmetic)

-(instancetype)add:other;
-(instancetype)mul:other;
-(instancetype)sub:other;
-(instancetype)div:other;
-(double)log;
-(double)log10;
-(instancetype)abs;
-fib;
-slowfib;
@end
