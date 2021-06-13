//
//  MPWSkipFilter.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 12.06.21.
//

#import "MPWSkipFilter.h"

@interface MPWSkipFilter()

@property (nonatomic, assign)  long skipped;


@end

@implementation MPWSkipFilter

-(void)writeObject:(id)anObject
{
    if ( _skipped >= _skip) {
        [self.target writeObject:anObject];
    } else {
        _skipped++;
    }
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWSkipFilter(testing) 

+(void)testSkip1Item
{
    MPWSkipFilter *skipper=[MPWSkipFilter stream];
    skipper.skip = 1;
    [[skipper do] writeObject:[@[@"one",@"two",@"three"] each]];
    IDEXPECT( skipper.target, ( @[@"two",@"three"]),@"skipped one item");
    
}

+(void)testSkipNone
{
    MPWSkipFilter *skipper=[MPWSkipFilter stream];
    [[skipper do] writeObject:[@[@"one",@"two",@"three"] each]];
    IDEXPECT( skipper.target, ( @[@"one",@"two",@"three"]),@"skipped no items");
    
}

+(NSArray*)testSelectors
{
   return @[
       @"testSkip1Item",
       @"testSkipNone",
        ];
}

@end
