//
//  MPWExtensionAdder.m
//  MPWFoundationFramework
//
//  Created by Marcel Weiher on 31.03.23.
//

#import "MPWExtensionAdder.h"



@implementation MPWExtensionAdder

-(void)writeString:(NSString*)aPath
{
    NSString *processedPath = [aPath stringByDeletingPathExtension];
    if ( self.extension ) {
        processedPath = [processedPath stringByAppendingPathExtension:self.extension];
    }
    FORWARD(processedPath);
}


-(void)dealloc
{
    [_extension release];
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWExtensionAdder(testing) 

+(void)testExtensionRemovedAndAdded
{
    NSMutableArray *result=[NSMutableArray array];
    MPWExtensionAdder *ext=[self streamWithTarget:result];
    [ext writeObject:@"hello.txt"];
    IDEXPECT(result.firstObject, @"hello", @"remove");
    [result removeAllObjects];
    ext.extension = @"html";
    [ext writeObject:@"index"];
    IDEXPECT(result.firstObject, @"index.html", @"add");
    [result removeAllObjects];
    [ext writeObject:@"index.txt"];
    IDEXPECT(result.firstObject, @"index.html", @"remove then add");
}

+(NSArray*)testSelectors
{
   return @[
       @"testExtensionRemovedAndAdded",
			];
}

@end
