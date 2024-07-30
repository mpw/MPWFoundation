//
//  MPWPropertyPathDefs.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 29.07.24.
//

#ifndef MPWPropertyPathDefs_h
#define MPWPropertyPathDefs_h

typedef struct {
    void  * _Nullable propertyPath;
    _Nullable IMP      function;
    void *   _Nullable method;
} PropertyPathDef;

typedef struct {
    MPWRESTVerb verb;
    int count;
    PropertyPathDef defs[];
} PropertyPathDefs;




#endif /* MPWPropertyPathDefs_h */
