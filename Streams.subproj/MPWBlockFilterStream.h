//
//  MPWBlockFilterStream.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 8/15/12.
//
//

#import <MPWFoundation/MPWFilter.h>


@interface MPWBlockFilterStream : MPWFilter
{
    id block;
}

idAccessor_h( block, setBlock )

+(instancetype)streamWithBlock:aBlock;

@end
