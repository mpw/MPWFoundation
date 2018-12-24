//
//  MPWBoxerUnboxer.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 3/6/14.
//
//

#import "MPWBoxerUnboxer.h"
#import "MPWPoint.h"
#import "MPWRect.h"
#import "AccessorMacros.h"

@interface MPWNSPointBoxer : MPWBoxerUnboxer  @end
@interface MPWNSRectBoxer : MPWBoxerUnboxer  @end
@interface MPWBlockBoxer : MPWBoxerUnboxer

-initWithBoxer:(BoxBlock)newBoxer unboxer:(UnboxBlock)newUnboxer;

@property (strong,nonatomic) UnboxBlock unboxBlock;
@property (strong,nonatomic) BoxBlock boxBlock;
@property (strong,nonatomic) BoxVarargBlock boxVarargBlock;


@end

@implementation MPWBoxerUnboxer

static NSMutableDictionary *conversionDict;

+(NSMutableDictionary*)createConversionDict
{
    return [[@{
               @(@encode(NSPoint)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(NSSize)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(NSRect)): [MPWBoxerUnboxer nsrectBoxer],
#ifdef CGPoint
               @(@encode(CGPoint)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(CGSize)): [MPWBoxerUnboxer nspointBoxer],
               @(@encode(CGRect)): [MPWBoxerUnboxer nsrectBoxer],
#endif
               } mutableCopy] autorelease];
}

static NSMutableDictionary *conversionDict;

+(NSMutableDictionary*)conversionDict
{
    if ( !conversionDict ) {
        conversionDict=[[self createConversionDict] retain];
    }
    return conversionDict;
}


+(void)setBoxer:(MPWBoxerUnboxer*)aBoxer forTypeString:(NSString*)typeString
{
    return [[self conversionDict] setObject:aBoxer forKey:typeString];
}

+(MPWBoxerUnboxer*)converterForType:(const char*)typeString
{
    return [[self conversionDict] objectForKey: @(typeString)];
}


+(MPWBoxerUnboxer*)converterForTypeString:(NSString*)typeString
{
    return [[self conversionDict] objectForKey: typeString];
}


+nspointBoxer
{
    return [[MPWNSPointBoxer new] autorelease];
}

+nsrectBoxer
{
    return [[MPWNSRectBoxer new] autorelease];
}


+boxer:(BoxBlock)newBoxer unboxer:(UnboxBlock)newUnboxer
{
    return [[[MPWBlockBoxer alloc] initWithBoxer:newBoxer unboxer:newUnboxer] autorelease];
}


-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    @throw [NSException exceptionWithName:@"notimplemented" reason:@"unbox not implemented" userInfo:nil];
}

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    @throw [NSException exceptionWithName:@"notimplemented" reason:@"unbox not implemented" userInfo:nil];
}

-boxedObjectForVararg:(va_list)ap;
{
    @throw [NSException exceptionWithName:@"notimplemented" reason:@"boxedObjectForVararg not implemented" userInfo:nil];
}



@end


@implementation MPWNSPointBoxer

-(id)boxedObjectForVararg:(va_list)ap
{
    NSPoint p=va_arg(ap, NSPoint);
    return [MPWPoint pointWithNSPoint:p];
}

-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    *(NSPoint*)buffer = [(MPWPoint*)anObject pointValue];
}

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    id retval= [MPWPoint pointWithNSPoint:*(NSPoint*)buffer];
    return retval;
}

@end



@implementation MPWNSRectBoxer

-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    *(NSRect*)buffer = [anObject rectValue];
}

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    id retval= [MPWRect rectWithNSRect:*(NSRect*)buffer];
    return retval;
}

-(id)boxedObjectForVararg:(va_list)ap
{
    NSRect r=va_arg(ap, NSRect);
    return [MPWRect rectWithNSRect:r];
}


@end



@implementation MPWBlockBoxer

-initWithBoxer:(BoxBlock)newBoxer unboxer:(UnboxBlock)newUnboxer vararg:(BoxVarargBlock)newVarArgBoxer;
{
    self=[super init];
    self.boxBlock = newBoxer;
    self.unboxBlock = newUnboxer;
    self.boxVarargBlock = newVarArgBoxer;
    return self;
}

-initWithBoxer:(BoxBlock)newBoxer unboxer:(UnboxBlock)newUnboxer
{
    return [self initWithBoxer:newBoxer unboxer:newUnboxer vararg:nil];
}

-(void)unboxObject:anObject intoBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    self.unboxBlock( anObject, buffer, maxBytes);
}

-boxedObjectForBuffer:(void*)buffer maxBytes:(int)maxBytes
{
    return self.boxBlock( buffer, maxBytes);
}

-(id)boxedObjectForVararg:(va_list)ap
{
    if ( self.boxVarargBlock) {
        return self.boxVarargBlock( ap );
    } else {
        return nil;
    }
        
}

-(void)dealloc
{
    [_unboxBlock release];
    [_boxBlock release];
    [_boxVarargBlock release];
    [super dealloc];
}



@end


