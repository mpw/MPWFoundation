//
//  MPWBlockInvocable.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 5/4/11.
//  Copyright 2012 metaobject ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


struct Block_descriptor {
    unsigned long int reserved;
    
    /** Total size of the described block, including imported variables. */
    unsigned long int size;
    
    /** Optional block copy helper. May be NULL. */
    void (*copy)(void *dst, void *src);
    
    /** Optional block dispose helper. May be NULL. */
    void (*dispose)(void *);
};


@interface MPWBlockInvocable : NSObject {
	int	flags,reserved;
    IMP invoke;
	struct Block_descriptor *descriptor;
}

@end
