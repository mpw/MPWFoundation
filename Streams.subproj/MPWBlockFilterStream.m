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

+(instancetype)streamWithBlock:aBlock
{
    MPWBlockFilterStream *s=[self stream];
    [s setBlock:aBlock];
    return s;
}

-(void)writeObject:(id)anObject sender:aSender
{
    filterBlock theFilter = (filterBlock)[self block];
    if ( theFilter) {
        id processed =theFilter(anObject);
        if ( processed ) {
            [target writeObject:processed sender:aSender];
        }
    }
}

-(void)writeObject:(id)anObject
{
    [self writeObject:anObject sender:nil];
}

-(void)dealloc
{
    [block release];
    [super dealloc];
}

@end

#import "DebugMacros.h"


@implementation MPWBlockFilterStream(testing)


+(void)testUppercase
{
    id stream=[self streamWithBlock:^(id input){ return [input uppercaseString];}];
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
