//
//  MPWDirectoryReference.h
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


@class MPWStructureDefinition;

@interface MPWDirectoryReference : MPWReference
{
    NSArray *contents;
    BOOL    fancy;
}

-(instancetype)initWithContents:(NSArray*)newContents;
-(NSArray*)contents;
-(NSArray*)dicts;

@property (readonly) long count;
/// Structural view of this legacy directory listing.
@property (nonatomic, readonly) MPWStructureDefinition *structureDefinition;

@end
