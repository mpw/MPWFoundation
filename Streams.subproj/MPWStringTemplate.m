//
//  MPWStringTemplate.m
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 04.02.24.
//

#import "MPWStringTemplate.h"
#import "MPWByteStream.h"

@interface MPWStringTemplate()

@property(nonatomic,strong) NSMutableArray *fragments;

@end

@implementation MPWStringTemplate

-(void)parseString:(NSString*)s
{
    //    NSLog(@"writeInterpolatedString: %@ withEnvironment: %@",s,env);
    NSMutableArray *frags=self.fragments;
    long curIndex=0;
    long maxIndex=[s length];
    while (curIndex < maxIndex) {
        
        NSRange leftBrace=[s rangeOfString:@"{"
                                   options:0
                                     range:NSMakeRange(curIndex,maxIndex-curIndex)];
        if ( leftBrace.location == NSNotFound ) {
            break;
        }
        if ( !isascii([s characterAtIndex:leftBrace.location+1]) ) {
            curIndex=leftBrace.location+1;
            continue;
        }
        [frags addObject:[s substringWithRange:NSMakeRange(curIndex, leftBrace.location-curIndex)]];
        curIndex = leftBrace.location + leftBrace.length + 1;
        NSRange rightBrace=[s rangeOfString:@"}"
                                    options:0
                                      range:NSMakeRange(curIndex,maxIndex-curIndex)];
        if ( rightBrace.location == NSNotFound ) {
            break;
        }
        curIndex = rightBrace.location + rightBrace.length + 1;
        NSRange varRange=NSMakeRange( leftBrace.location+1, rightBrace.location-leftBrace.location-1);
        NSString *varName=[s substringWithRange:varRange];
        [frags addObject:varName];
//        [self outputString:[s         curIndex = rightBrace.location+1;
    }
    if ( curIndex <= maxIndex ) {
        [frags addObject:[s substringFromIndex:curIndex-1]];
    }
}


CONVENIENCEANDINIT(template, initWithString:(NSString*)aString)
{
    self=[super init];
    self.fragments=[NSMutableArray array];
    [self parseString:aString];
    return self;
}

-(void)writeOnByteStream:(MPWByteStream*)aStream withBindings:(NSDictionary*)bindings
{
    NSArray *frags=self.fragments;
    for (int i=0;i<frags.count;i+=2 ) {
        [aStream outputString:frags[i]];
        if (i+1 < frags.count ) {
            [aStream writeObject:bindings[frags[i+1]]];
        }
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWStringTemplate(testing) 


+(void)testNumberOfParsedFragments
{
    INTEXPECT([self templateinitWithString:@"first {var} second"].fragments.count, 3, @"number of fragments parsed");
}

+(void)testParsedFragments
{
    IDEXPECT([self templateinitWithString:@"first{var}second"].fragments, (@[@"first",@"var",@"second"]), @"ragments parsed");
}

+(void)testAlwaysStartWithConstantStringEvenIfEmpty
{
    INTEXPECT([self templateinitWithString:@"{var} second"].fragments.count, 3, @"number of fragments parsed");
}

+(void)testWriteResultWithSubstition
{
    MPWStringTemplate *t=[self templateinitWithString:@"first {var} second"];
    MPWByteStream *output=[MPWByteStream streamWithTarget:[NSMutableString string]];
    [t writeOnByteStream:output withBindings:@{ @"var": @"value of var"}];
    IDEXPECT( output.target, @"first value of var second",@"substituted");
}

+(NSArray*)testSelectors
{
   return @[
			@"testNumberOfParsedFragments",
            @"testParsedFragments",
            @"testAlwaysStartWithConstantStringEvenIfEmpty",
            @"testWriteResultWithSubstition"
			];
}

@end
