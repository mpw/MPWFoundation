//
//  MPWExtensionMapper.m
//  MPWFoundation
//
//  Created by Marcel Weiher on 04.11.21.
//

#import "MPWExtensionMapper.h"

@implementation MPWExtensionMapper

-reverseMapReference:aReference {
    return [[aReference path] stringByAppendingPathExtension: self.extension];
}
-mapReference:aReference {
    return [[aReference path] stringByDeletingPathExtension];
}

-(void)dealloc
{
    [_extension release];
    [super dealloc];
}

@end
