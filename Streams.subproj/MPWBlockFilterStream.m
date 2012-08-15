//
//  MPWBlockFilterStream.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/15/12.
//
//

#import "MPWBlockFilterStream.h"

@implementation MPWBlockFilterStream

typedef id (^filterBlock)(id );

idAccessor( block, setBlock )

-(void)writeObject:(id)anObject
{
    filterBlock theFilter = (filterBlock)[self block];

    [target writeObject:theFilter(anObject)];
}

-(void)dealloc
{
    [block release];
    [super dealloc];
}

@end


@implementation MPWBlockFilterStream(testing)


+(void)testUppercase
{
    id stream=[self stream];
    [stream setBlock:^(id input){ return [input uppercaseString];}];
    [stream writeObject:@"lower"];
    IDEXPECT([[stream target] lastObject], @"LOWER", @"lower as uppercase after filtering");
}


+testSelectors
{
    return [NSArray arrayWithObjects:
            @"testUppercase",
             nil];
}
@end