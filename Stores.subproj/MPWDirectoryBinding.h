//
//  MPWDirectoryBinding.h
//  ObjectiveSmalltalk
//
//  Created by Marcel Weiher on 5/24/14.
//
//

#import <MPWFoundation/MPWReference.h>

@protocol DirectoryPrinting

-(void)writeDirectory:aDirectory;
-(void)writeFancyDirectory:aDirectory;


@end


@interface MPWDirectoryBinding : MPWReference
{
    NSArray *contents;
    BOOL    fancy;
}

-(instancetype)initWithContents:(NSArray*)newContents;
-(NSArray*)contents;
-(NSArray*)dicts;

@property (readonly) long count;

@end
