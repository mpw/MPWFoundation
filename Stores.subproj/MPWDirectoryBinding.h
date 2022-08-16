//
//  MPWDirectoryBinding.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/24/14.
//
//

#import <MPWFoundation/MPWBinding.h>

@protocol DirectoryPrinting

-(void)writeDirectory:aDirectory;
-(void)writeFancyDirectory:aDirectory;


@end


@interface MPWDirectoryBinding : MPWBinding
{
    NSArray *contents;
    BOOL    fancy;
}

-(instancetype)initWithContents:(NSArray*)newContents;
-(NSArray*)contents;

@property (readonly) long count;

@end
