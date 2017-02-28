//
//  MPWObject_fastrc.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 6/14/12.
//
//

#import <MPWFoundation/MPWObject.h>

static inline id _retainMPWObject( MPWObject *obj ) {
    if ( obj ) {
        (obj->_retainCount)++; 
    }
    return obj;
}

static inline void _releaseMPWObject( MPWObject *obj ) {
    if (obj && (--(obj->_retainCount) < 0)  ) {
        [obj mydealloc];
    }
}
