//
//  MPWBlock.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 09.12.22.
//

#import "MPWBlock.h"


static struct Block_descriptor sdescriptor= {
    0, 64, NULL, NULL
};


@implementation MPWBlock

-(instancetype)init
{
    if (self=[super init]) {
        descriptor=&sdescriptor;
        flags=1;
        //        flags|=(1 << 28);   // is global
        flags|=(1 << 24);  // we are a heap block
        typeSignature="@@:@@";
    }
    return self;
}

-(void)setFun:(IMP)theFun
{
    invoke=theFun;
}

-value
{
    return ((id (*)(id block ))invoke)(self);
}

-value:arg
{
    return ((id (*)(id block,id arg ))invoke)(self,arg);
}

-value:arg with:arg2
{
    return ((id (*)(id block,id arg, id arg2 ))invoke)(self,arg,arg2);
}

@end


#import <MPWFoundation/DebugMacros.h>

typedef int (^intBlock)(int arg );
typedef id (^idBlock)(id arg );


@implementation MPWBlock(testing) 

int theFun( id theBlock, int arg ) {
    return arg+23;
}

+(void)testInvocationAsBlock
{
    MPWBlock *block=[MPWBlock new];
    [block setFun:theFun];
    intBlock cBlock=(intBlock)block;
    int result=cBlock(5);
    INTEXPECT(result, 28, @"called the block");
}

int theIdFun( id theBlock, id arg ) {
    return @([arg intValue]+51);
}


+(void)testBlockValue
{
    MPWBlock *block=[MPWBlock new];
    [block setFun:theIdFun];
    idBlock cBlock=(idBlock)block;
    id result=[block value:@(20)];
    IDEXPECT(result, @(71), @"called the block");
}

+(NSArray*)testSelectors
{
   return @[
       @"testInvocationAsBlock",
       @"testBlockValue",
			];
}

@end
