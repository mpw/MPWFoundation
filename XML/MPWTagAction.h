//
//  MPWTagAction.h
//  ObjectiveXML
//
//  Created by Marcel Weiher on 7/12/12.
//
//

#import <Foundation/Foundation.h>

@class MPWFastInvocation;

@interface MPWTagAction : NSObject
{
    NSString *mappedName;
    NSString *tagNamespace;
    NSString *namespacePrefix;
    @public
    NSString *tagName;
    MPWFastInvocation *tagAction;
    MPWFastInvocation *elementAction;
}

+undeclaredElementAction;

-initWithTagName:(NSString*)tag;
+tagActionWithName:(NSString*)tag;
-(NSString*)tagName;
-(void)setTagName:(NSString*)newName;
-(MPWFastInvocation*)tagAction;
-(void)setMappedName:(NSString*)newMappedName;
-(void)setElementInvocationForTarget:primary backup:backup;
-(void)setNamespacePrefix:(NSString*)aPrefix;
-(void)setTagInvocationForTarget:primaryTarget;

@property (nonatomic, strong) MPWFastInvocation* elementAction;

@end
