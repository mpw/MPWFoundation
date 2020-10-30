//
//  MPWValueArray.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 30.10.20.
//

#import "MPWValueArray.h"

#define MPWVALUEARRAY(someType)   ([MPWValueArray arrayWithElementSize:(sizeof (someType))]);

@implementation MPWValueArray
{
    long    capacity;
    long    count;
    unsigned char    *data;
    int    elementSize;
}

+(instancetype)arrayWithElementSize:(int)elemSize
{
    return [[[self alloc] iniitWithElementSize:elemSize] autorelease];
}

-(instancetype)iniitWithElementSize:(int)elemSize
{
    if ( self=[super init]) {
        capacity=20;
        count=0;
        elementSize=elemSize;
        data=malloc( elemSize * (capacity+2));
    }
    return self;
}

-(void)addElementPtr:(void*)someElement
{
    count++;
    [self at:count-1 putPtr:someElement];
}


-(void)at:(long)anIndex putPtr:(void*)someElement
{
    if ( anIndex >0 && anIndex < count ) {
        memcpy( data + (anIndex*elementSize), someElement, elementSize);
    }
}

-(void*)ptrAt:(long)anIndex
{
    return data + (anIndex*elementSize);
}

@end




#import <MPWFoundation/DebugMacros.h>

@implementation MPWValueArray(testing) 

+(void)createArrayAndStoreRetrievePoint
{
    MPWValueArray *array=MPWVALUEARRAY( NSPoint );
    NSPoint p={ 23 ,45};
    NSPoint retrieved={1,2};
    NSPoint *retrievedPtr;

    *((NSPoint*)[array ptrAt:0])=p;
    retrievedPtr=[array ptrAt:0];
    retrieved=*retrievedPtr;
    FLOATEXPECT(retrieved.x, 23, @"x");
    FLOATEXPECT(retrieved.y, 45, @"x");
}

+(NSArray*)testSelectors
{
   return @[
			@"createArrayAndStoreRetrievePoint",
			];
}

@end
