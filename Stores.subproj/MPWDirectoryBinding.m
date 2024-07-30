//
//  MPWDirectoryBinding.m
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/24/14.
//
//

#import "MPWDirectoryBinding.h"
#import <AccessorMacros.h>


@implementation MPWDirectoryBinding

objectAccessor(NSArray*, contents, setContents)
boolAccessor(fancy, setFancy)

-(instancetype)initWithContents:(NSArray *)newContents
{
    self=[super init];
    [self setContents:newContents];
    return self;
}

-children
{
    return contents;
}

-paths
{
    return [[[self contents] collect] path];
}

-dicts
{
    NSMutableArray *dicts=[NSMutableArray array];
    for ( id <MPWIdentifying> ref in self.contents) {
        [dicts addObject:@{ @"name": ref.path , @"value": self.store[ref] }];
    }
    return dicts;
}

-(long)count
{
    return contents.count;
}

-(void)dealloc
{
    [contents release];
    [super dealloc];
}

-(void)writeOnShellPrinter:aPrinter
{
    if ( [self fancy] ) {
        [aPrinter writeFancyDirectory:self];
    } else {
        [aPrinter writeDirectory:self];
    }
}

-(id)l
{
    MPWDirectoryBinding *d=[[[[self class] alloc] initWithContents:[self contents]] autorelease];
    [d setFancy:YES];
    return d;
}

@end
