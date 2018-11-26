/* MPWScanner.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>
#import <MPWFoundation/AccessorMacros.h>
#import <MPWFoundation/MPWObject.h>

typedef id (*IDIMP0)(id, SEL);


@interface MPWScanner : NSObject
{
    NSData *data;
    id	dataSource;
    const char *start,*end,*pos,*probe;
    NSMutableDictionary		*handlers;
    id defaultHandler;
    IDIMP0	  charSwitch[260];
    id textCache;
    IMP0 getObject;
    IMP0 initData;
    IMPINT1 makeText;
    IMP1 setScanPosition;
    long	headRoom;
    id bufferCache;
}
idAccessor_h( dataSource, setDataSource )
-sourceNextObject;
-(void)_initCharSwitch;			//---	only for subclasses
+(NSArray*)scan:(NSData*)data;
+scannerWithDataSource:aDataSource;
+scannerWithData:(NSData*)aData;
-initWithData:(NSData*)aData;
-(void)addData:(NSData*)newData;
-initWithDataSource:aDataSource;
-(void)addHandler:aHandler forKey:(NSString*)aKey;
-handlerForKey:(NSString*)aKey;
-makeText:(long)length;
-makeString:(long)length;
-(void)skipTo:(NSString*)aString;
-(void)skipEOL;
-nextLine;
-nextObject;


-(void)setScanPosition:(const  char*)newPos;
-(const char*)position;
-(long)bufLen;
-(BOOL)reserve:(long)roomNeeded;
-(long)offset;

#define UPDATEPOSITION(newPos)		setScanPosition(self, @selector(setScanPosition:), (void*)newPos )
#define MAKE_PROBE_CURRENT		UPDATEPOSITION(probe)
#define SCANINBOUNDS(ptr)		((ptr)<end)
#define RESERVE(room)			((pos+(room)<end) ? YES : [self reserve:(room)])

@end

@interface NSObject(TestSupport)

+(void)testFile:(NSString*)filename;
+(void)test:(NSString*)filename;
+(void)test;

@end
