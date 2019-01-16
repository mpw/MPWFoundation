//
//  MPWIntArray.m
//  MPWFoundation
//
//  Created by Marcel Weiher on Sat Dec 27 2003.
/*  
    Copyright (c) 2003-2017 by Marcel Weiher.  All rights reserved.
*/
//

#import "MPWIntArray.h"
#import <Foundation/Foundation.h>
#import "DebugMacros.h"
//#if !TARGET_OS_WATCH
//#import <Accelerate/Accelerate.h>
//#endif

@implementation MPWIntArray

+(instancetype)array
{
	return [[[self alloc] init] autorelease];
}

-(instancetype)initWithCapacity:(unsigned long)newCapacity
{
    if ( self = [super init] ) {
		capacity=newCapacity;
		count=0;
		data=malloc( (capacity+3) * sizeof(int) );
	}
    return self;
}

-(instancetype)init
{
	return [self initWithCapacity:10];
}

-(instancetype)initFromInt:(long)start toInt:(long)stop step:(long)step
{
    long theCount=(stop-start)/step + 2;
    self=[self initWithCapacity:theCount];
    for (int i=0;i<theCount;i++) {
        data[i]=(int)(start+i*step);
    }
    count=theCount;
    return self;
}

-(int)integerAtIndex:(unsigned)index
{
	if ( index < count ) {
		return data[index];
	} else {
		[NSException raise:@"MPWRangeException" format:@"%@ range exception: %d beyond count: %ld (capacity: %ld)",[self class],index,count,capacity];
		return 0;
	}
}

-(void)_growTo:(unsigned long)newCapacity
{
    capacity=capacity*2+2;
	capacity=MAX( capacity, newCapacity );
    if ( data ) {
        data=realloc( data, (capacity+3)*sizeof(int) );
    } else {
        data=calloc( (capacity+3), sizeof(int) );
    }
}


-(void)addIntegers:(int*)intArray count:(unsigned long)numIntsToAdd
{
	unsigned long newCount=count+numIntsToAdd;
	if ( newCount >= capacity ) {
		[self _growTo:newCount];
	}
	memcpy( data+count, intArray, numIntsToAdd * sizeof(int));
	count=newCount;
}


-(instancetype)copy
{
    MPWIntArray *copy=[[[self class] alloc] initWithCapacity:capacity];
    [copy addIntegers:data count:count];
    return copy;
}


-(void)addInteger:(int)anInt
{
	unsigned long newCount=count+1;
	if ( newCount >= capacity ) {
		[self _growTo:newCount];
	}
    data[count]=anInt;
    count=newCount;
}

-(void)addObject:anObject
{
	[self addInteger:[anObject intValue]];
}

-(void)removeLastObject
{
    if ( count) {
        count--;
    }
}

-(void)replaceIntegerAtIndex:(unsigned long)anIndex withInteger:(int)anInt
{
	if ( anIndex < count ) {
		data[anIndex]=anInt;
	} else {
		[NSException raise:@"MPWRangeException" format:@"%@ range exception: %ld beyond count: %ld (capacity: %ld)",[self class],anIndex,count,capacity];
	}
}

-(void)replaceObjectAtIndex:(unsigned)anIndex withObject:anObject
{
	[self replaceIntegerAtIndex:anIndex withInteger:[anObject intValue]];
}

-(void)dealloc
{
	if ( data ) {
		free(data);
	}
	[super dealloc];
}

-(NSUInteger)count
{
	return count;
}

-(void)reset
{
    count=0;
}

-(int*)integers
{
    return data;
}

-(int)lastInteger
{
    return data[count-1];
}

-description
{
	if ( [self count] ) {
		NSMutableString *description=[NSMutableString stringWithFormat:@"( %d",[self integerAtIndex:0]];
		for (int i=1;i<[self count];i++) {
			[description appendFormat:@", %d",[self integerAtIndex:i]];
		}
		[description appendString:@")"];
		return description;
	} else {
		return @"( )";
	}
}

static void doSort(int a[], int left, int right);


static void dualPivotQuicksort(int a[], int left, int right) {
    // Compute indices of five evenly spaced elements
    int sixth = (right - left + 1) / 6;
    int e1 = left  + sixth;
    int e5 = right - sixth;
    int e3 = (left + right) / 2; // The midpoint
    int e4 = e3 + sixth;
    int e2 = e3 - sixth;
    
    // Sort these elements using a 5-element sorting network
    int ae1 = a[e1], ae2 = a[e2], ae3 = a[e3], ae4 = a[e4], ae5 = a[e5];
    
    if (ae1 > ae2) { int t = ae1; ae1 = ae2; ae2 = t; }
    if (ae4 > ae5) { int t = ae4; ae4 = ae5; ae5 = t; }
    if (ae1 > ae3) { int t = ae1; ae1 = ae3; ae3 = t; }
    if (ae2 > ae3) { int t = ae2; ae2 = ae3; ae3 = t; }
    if (ae1 > ae4) { int t = ae1; ae1 = ae4; ae4 = t; }
    if (ae3 > ae4) { int t = ae3; ae3 = ae4; ae4 = t; }
    if (ae2 > ae5) { int t = ae2; ae2 = ae5; ae5 = t; }
    if (ae2 > ae3) { int t = ae2; ae2 = ae3; ae3 = t; }
    if (ae4 > ae5) { int t = ae4; ae4 = ae5; ae5 = t; }
    
    a[e1] = ae1; a[e3] = ae3; a[e5] = ae5;
    
    /*
     * Use the second and fourth of the five sorted elements as pivots.
     * These values are inexpensive approximations of the first and
     * second terciles of the array. Note that pivot1 <= pivot2.
     *
     * The pivots are stored in local variables, and the first and
     * the last of the elements to be sorted are moved to the locations
     * formerly occupied by the pivots. When partitioning is complete,
     * the pivots are swapped back into their final positions, and
     * excluded from subsequent sorting.
     */
    int pivot1 = ae2; a[e2] = a[left];
    int pivot2 = ae4; a[e4] = a[right];
    
    // Pointers
    int less  = left  + 1; // The index of first element of center part
    int great = right - 1; // The index before first element of right part
    
    BOOL pivotsDiffer = (pivot1 != pivot2);
    
    if (pivotsDiffer) {
        /*
         * Partitioning:
         *
         *   left part         center part                    right part
         * +------------------------------------------------------------+
         * | < pivot1  |  pivot1 <= && <= pivot2  |    ?    |  > pivot2 |
         * +------------------------------------------------------------+
         *              ^                          ^       ^
         *              |                          |       |
         *             less                        k     great
         *
         * Invariants:
         *
         *              all in (left, less)   < pivot1
         *    pivot1 <= all in [less, k)     <= pivot2
         *              all in (great, right) > pivot2
         *
         * Pointer k is the first index of ?-part
         */
    outer:
        for (int k = less; k <= great; k++) {
            int ak = a[k];
            if (ak < pivot1) { // Move a[k] to left part
                if (k != less) {
                    a[k] = a[less];
                    a[less] = ak;
                }
                less++;
            } else if (ak > pivot2) { // Move a[k] to right part
                while (a[great] > pivot2) {
                    if (great-- == k) {
                        goto outer;
                    }
                }
                if (a[great] < pivot1) {
                    a[k] = a[less];
                    a[less++] = a[great];
                    a[great--] = ak;
                } else { // pivot1 <= a[great] <= pivot2
                    a[k] = a[great];
                    a[great--] = ak;
                }
            }
        }
    } else { // Pivots are equal
        /*
         * Partition degenerates to the traditional 3-way,
         * or "Dutch National Flag", partition:
         *
         *   left part   center part            right part
         * +----------------------------------------------+
         * |  < pivot  |  == pivot  |    ?    |  > pivot  |
         * +----------------------------------------------+
         *              ^            ^       ^
         *              |            |       |
         *             less          k     great
         *
         * Invariants:
         *
         *   all in (left, less)   < pivot
         *   all in [less, k)     == pivot
         *   all in (great, right) > pivot
         *
         * Pointer k is the first index of ?-part
         */
        for (int k = less; k <= great; k++) {
            int ak = a[k];
            if (ak == pivot1) {
                continue;
            }
            if (ak < pivot1) { // Move a[k] to left part
                if (k != less) {
                    a[k] = a[less];
                    a[less] = ak;
                }
                less++;
            } else { // (a[k] > pivot1) -  Move a[k] to right part
                /*
                 * We know that pivot1 == a[e3] == pivot2. Thus, we know
                 * that great will still be >= k when the following loop
                 * terminates, even though we don't test for it explicitly.
                 * In other words, a[e3] acts as a sentinel for great.
                 */
                while (a[great] > pivot1) {
                    great--;
                }
                if (a[great] < pivot1) {
                    a[k] = a[less];
                    a[less++] = a[great];
                    a[great--] = ak;
                } else { // a[great] == pivot1
                    a[k] = pivot1;
                    a[great--] = ak;
                }
            }
        }
    }
    
    // Swap pivots into their final positions
    a[left]  = a[less  - 1]; a[less  - 1] = pivot1;
    a[right] = a[great + 1]; a[great + 1] = pivot2;
    
    // Sort left and right parts recursively, excluding known pivot values
    doSort(a, left,   less - 2);
    doSort(a, great + 2, right);
    
    /*
     * If pivot1 == pivot2, all elements from center
     * part are equal and, therefore, already sorted
     */
    if (!pivotsDiffer) {
        return;
    }
    
    /*
     * If center part is too large (comprises > 2/3 of the array),
     * swap internal pivot values to ends
     */
    if (less < e1 && great > e5) {
        while (a[less] == pivot1) {
            less++;
        }
        while (a[great] == pivot2) {
            great--;
        }
        
        /*
         * Partitioning:
         *
         *   left part       center part                   right part
         * +----------------------------------------------------------+
         * | == pivot1 |  pivot1 < && < pivot2  |    ?    | == pivot2 |
         * +----------------------------------------------------------+
         *              ^                        ^       ^
         *              |                        |       |
         *             less                      k     great
         *
         * Invariants:
         *
         *              all in (*, less)  == pivot1
         *     pivot1 < all in [less, k)   < pivot2
         *              all in (great, *) == pivot2
         *
         * Pointer k is the first index of ?-part
         */
    outer1:
        for (int k = less; k <= great; k++) {
            int ak = a[k];
            if (ak == pivot2) { // Move a[k] to right part
                while (a[great] == pivot2) {
                    if (great-- == k) {
                        goto outer1;
                    }
                }
                if (a[great] == pivot1) {
                    a[k] = a[less];
                    a[less++] = pivot1;
                } else { // pivot1 < a[great] < pivot2
                    a[k] = a[great];
                }
                a[great--] = pivot2;
            } else if (ak == pivot1) { // Move a[k] to left part
                a[k] = a[less];
                a[less++] = pivot1;
            }
        }
    }
    
    // Sort center part recursively, excluding known pivot values
    doSort(a, less, great);
}

#define INSERTION_SORT_THRESHOLD 10

static void doSort(int a[], int left, int right) {
    // Use insertion sort on tiny arrays
    if (right - left + 1 < INSERTION_SORT_THRESHOLD) {
        for (int i = left + 1; i <= right; i++) {
            int ai = a[i];
            int j;
            for (j = i - 1; j >= left && ai < a[j]; j--) {
                a[j + 1] = a[j];
            }
            a[j + 1] = ai;
        }
    } else { // Use Dual-Pivot Quicksort on large arrays
        dualPivotQuicksort(a, left, right);
    }
}


-(void)dualPivotQuicksort
{
    doSort(data, 0, (int)(count -1));
}



static int compareIntegerPointers(const void *va , const void *vb )
{
    const int *a=va,*b=vb;
    return *a  - *b;
}

-(void)systemQuicksortFunction
{
    qsort(data, count, sizeof(int), compareIntegerPointers);
}

-(void)sort
{
    [self systemQuicksortFunction];
}

-(MPWIntArray *)sorted
{
    MPWIntArray *sorted=[[self copy] autorelease];
    [sorted sort];
    return sorted;
}

-(void)do:(void(^)(int))block
{
    for (int i=0;i<count;i++) {
        block(data[i]);
    }
}


-(instancetype)select:(BOOL(^)(int))block
{
    MPWIntArray *result=[MPWIntArray array];
    for (int i=0;i<count;i++) {
        if ( block(data[i]) ) {
            [result addInteger:data[i]];
        }
    }
    return result;
}

@end


@implementation MPWIntArray(testing)

+(void)testArrayAccess
{
	id array=[self array];
	INTEXPECT( [array count], 0 ,@"count of empty array");
	[array addInteger:42];
	INTEXPECT( [array count],1 ,@"count after adding 1 element");
	INTEXPECT( [array integerAtIndex:0],42 ,@"value of element I put");
	[array addObject:@"50"];
	INTEXPECT( [array count],2 ,@"count after adding 2nd element");
	INTEXPECT( [array integerAtIndex:1],50 ,@"value of 2nd element I put");
}

+testSelectors
{
	return [NSArray arrayWithObjects:
		@"testArrayAccess",
		nil];
}

@end
