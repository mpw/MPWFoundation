//
//  MPWBlockInvocable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/4/11.
//  Copyright 2012 Marcel Weiher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


struct Block_descriptor {
	unsigned long int reserved;	// NULL
    unsigned long int size;         // sizeof(struct Block_literal_1)
	// optional helper functions
    void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
    void (*dispose_helper)(void *src);             // IFF (1<<25)
    // required ABI.2010.3.16
    const char *signature;                         // IFF (1<<30)
};

struct Block_struct
{
    void *isa;
    int  flags,reserved;
    IMP  invoke;
	struct Block_descriptor *descriptor;
};


@interface MPWBlockInvocable : NSObject {
	int	flags,reserved;
    IMP invoke;
	struct Block_descriptor *descriptor;
	IMP stub;
    char *typeSignature;
    int numParams;
}


-invokeWithTarget:target args:(va_list)args;
-(Method)installInClass:(Class)aClass withSignature:(const char*)signature selector:(SEL)aSelector oldIMP:(IMP*)oldImpPtr;
-(Method)installInClass:(Class)aClass withSignature:(const char*)signature selector:(SEL)aSelector;
-(void)installInClass:(Class)aClass withSignatureString:(NSString*)signature selectorString:(NSString*)selectorName;
-(IMP)stub;



@end
