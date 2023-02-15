/* NSObjectAdditions.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>

@interface NSObject(FramweworkPathAdditions)

+(NSString*)frameworkPath:(NSString*)aPath;
+(NSData*)frameworkResource:(NSString*)aPath category:(NSString*)category;
-(NSData*)frameworkResource:(NSString*)aPath category:(NSString*)category;

@end

@interface NSObject(ivarAccess)

//+(NSString*)ivarNameAtOffset:(int)ivarOffset;
+(NSString*)ivarNameAtOffset:(int)ivarOffset orIndex:(int)index;
+(NSString*)ivarNameForVarPointer:(const void*)address orIndex:(int)index ofInstance:(const void*)instaddr;
-(NSString*)ivarNameForVarPointer:(const void*)address orIndex:(int)index;
+(NSMutableArray*)allIvarNames;
+(NSMutableArray*)ivarNames;

@end

@interface NSObject(addressKey)

-addressKey;
@end

@interface NSObject(memberOfSet1)

-(id)memberOfSet:(NSSet*)aSet;

@end

@interface NSObject(debugLevel)

-(int)debugLevel;
-(void)setDebugLevel:(int)newLevel;

@end

@interface NSObject(stackCheck)


+(BOOL)isPointerOnStackAboveMe:(void*)ptr within:(long)maxDiff;
+(BOOL)isPointerOnStackAboveMe:(void*)ptr;
+(id)isPointerOnStackAboveMeForST:(void*)ptr;

@end
