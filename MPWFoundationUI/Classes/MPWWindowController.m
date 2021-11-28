//
//  MPWWindowController.m
//  MPWFoundationUI
//
//  Created by Marcel Weiher on 01.04.21.
//

#import "MPWWindowController.h"

@interface MPWWindowController ()

@end

@implementation MPWWindowController


-(NSString*)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    return self.titleAddition ? [NSString stringWithFormat:@"%@ - %@",displayName,self.titleAddition] : displayName;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self=[super initWithCoder:coder];
    self.view = [coder decodeObjectForKey:@"view"];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.view forKey:@"view"];
}

-(void)dealloc
{
    [_view release];
    [_viewController release];
    [super dealloc];
}

@end
