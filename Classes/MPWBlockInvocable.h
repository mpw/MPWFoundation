//
//  MPWBlockInvocable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/4/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <MPWFoundation/MPWBlock.h>


@interface MPWBlockInvocable : MPWBlock {
    int numParams;
}


-invokeWithTarget:target args:(va_list)args;
-(Method)installInClass:(Class)aClass withSignature:(const char*)signature selector:(SEL)aSelector oldIMP:(IMP*)oldImpPtr;
-(void)installInClass:(Class)aClass withSignature:(const char*)signature selector:(SEL)aSelector;
-(void)installInClass:(Class)aClass withSignatureString:(NSString*)signature selectorString:(NSString*)selectorName;
-(IMP)stub;



@end
