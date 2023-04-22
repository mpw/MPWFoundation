/* NSStringAdditions.h Copyright (c) 1998-2017 by Marcel Weiher, All Rights Reserved.
*/


#import <Foundation/Foundation.h>

@interface NSString(Additions)

-(NSString*)uniquedByNumberingInPool:(NSSet*)otherStrings;
-(NSString*)uniquedByNumberingInUpdatingPool:(NSMutableSet*)otherStrings;
-(int)countOccurencesOfCharacter:(int)c;

@end

@interface NSObject(StringAdditions)
/*"
     This is generic protocol for converting to #NSString and #NSData objects.
"*/

@property (readonly)  NSString *stringValue;

-(NSData*)asData;
-(NSArray<NSString*>*)resultsOfCommand;

@end

