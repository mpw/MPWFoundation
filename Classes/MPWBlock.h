//
//  MPWBlock.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 09.12.22.
//

#import <Foundation/Foundation.h>


#import <objc/runtime.h>


struct Block_descriptor {
    unsigned long int reserved;    // NULL
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

@interface MPWBlock : NSObject {
    int    flags,reserved;
    IMP invoke;
    struct Block_descriptor *descriptor;
    IMP stub;
    char *typeSignature;
}

@end

