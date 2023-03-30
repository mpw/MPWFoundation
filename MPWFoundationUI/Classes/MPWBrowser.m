//
//  MPWBrowser.m
//  ViewBuilderFramework
//
//  Created by Marcel Weiher on 06.03.19.
//  Copyright © 2019 Marcel Weiher. All rights reserved.
//

#import "MPWBrowser.h"
#import <MPWFoundation/MPWFoundation.h>
#import "NSViewAdditions.h"


@implementation MPWBrowser

-(float)defaultMinimumColumnWidth
{
    return 200;
}

-(instancetype)initWithFrame:(NSRect)frameRect
{
    self=[super initWithFrame:frameRect];
    [self setInternalDelegate:self];
    [self setMinColumnWidth:[self defaultMinimumColumnWidth]];
    return self;
}

+(instancetype)on:aStore
{
    MPWBrowser *browser=[[self new] autorelease];
    [browser setStore:aStore];
    return browser;
}

-(void)setRef:(MPWBinding*)aBinding
{
    self.store = aBinding.store;
    self.rootReference = aBinding.reference;
    [self loadColumnZero];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self setInternalDelegate:self];
}

-internalDelegate
{
    return [super delegate];
}

-(void)setInternalDelegate:newDelegate
{
    [super setDelegate:newDelegate];
}

-(id<MPWReferencing>)defaultRootReference
{
    return [self.store referenceForPath:@"."];
}

-(id<MPWReferencing>)currentReference
{
    return [self itemAtIndexPath:[self selectionIndexPath]];
}

//  Remove

-(BOOL)showClassMethods
{
    return NO;
}

-(MPWBinding*)rootBinding
{
    id <MPWReferencing> ref = self.rootReference;
    if ( !ref ) {
        ref=self.defaultRootReference;
    }
    return [self.store bindingForReference:ref inContext:nil];
}

-(NSArray*)listForItem:(MPWBinding*)binding
{
    if ( !binding ) {
        binding = [self rootBinding];
    }
    return [binding children];
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
    return [[self listForItem:item] count];
}


- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
    return [[self listForItem:item] objectAtIndex:index];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(MPWBinding*)item
{
    return ![item hasChildren];
}

-(NSString*)objectValueForReference:(id <MPWReferencing>)item
{
//    NSLog(@"item: %@",item);
    return [[item relativePathComponents] lastObject];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
    if ( [self.browserDelegate respondsToSelector:_cmd] ) {
        return [self.browserDelegate browser:self objectValueForItem:(id)item];
    } else {
        return [self objectValueForReference:item];
    }
}

-(NSDragOperation)browser:(NSBrowser *)browser validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger *)row column:(NSInteger *)column dropOperation:(NSBrowserDropOperation *)dropOperation
{
    return NSDragOperationCopy;
}

-(BOOL)dropPath:(NSString*)urlstring
{
    NSURL *url=[NSURL URLWithString:urlstring relativeToURL:nil];
    NSData *contents = [NSData dataWithContentsOfURL:url];
    NSString *name=[[url path] lastPathComponent];
//    NSLog(@"local file: %@ (%@  → '%@') with data of length: %ld",name,urlstring,[url path],(long)[contents length]);
    id <MPWReferencing> root=[self rootReference];
    NSString *path=[[root path] stringByAppendingPathComponent:name];
    id <MPWReferencing> newRef = [[self store] referenceForPath:path];
    [[self store] at:newRef put:contents];
    [self reloadColumn:0];
    return YES;}

- (BOOL)browser:(NSBrowser *)browser
     acceptDrop:(id<NSDraggingInfo>)info
          atRow:(NSInteger)row
         column:(NSInteger)column
  dropOperation:(NSBrowserDropOperation)dropOperation;
{
    NSPasteboard *pb=info.draggingPasteboard;
    NSString *urlstring=[pb stringForType:NSPasteboardTypeFileURL];
    return [self dropPath:urlstring];
}

-(IBAction)dumpGraphivViz:sender
{
    [self.store graphViz:[MPWByteStream Stderr]];
}


-(IBAction)showArchitecture:sender
{
    NSString *s=[self.store graphViz];
    NSString *full=[NSString stringWithFormat:@"digraph {   node [shape=rect style=rounded] %@ } ",s];
    id view = [NSClassFromString(@"MPWGraphVizView") new];
    [view openInWindow:@"Architecture"];
    [view performSelector:NSSelectorFromString(@"setDot:") withObject:full];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@:%p: on: %@ rootReference: %@>",self.className,self,self.store,self.rootReference];
}


@end

@implementation MPWBrowser(testing)

+(void)testDroppingStuff
{
    MPWBrowser *browser = [[[MPWBrowser alloc] initWithFrame:NSMakeRect(0,0,500,500)] autorelease];
    MPWDictStore *store=[MPWDictStore store];
    MPWBinding *binding=[MPWBinding bindingWithReference:@"" inStore:store];
    [browser setRef:binding];
    char filenametemplate[80]="/tmp/browserdroptest.XXXXXX";
    int fd = mkstemp( filenametemplate );
    char *content="Browser test content";
    write(fd, content, strlen(content));
    close(fd);
    NSString *path=[NSString stringWithUTF8String:filenametemplate];
    NSString *urlpath=[@"file://" stringByAppendingString:path];
    NSString *filename=[path lastPathComponent];
    [browser dropPath:urlpath];
    IDEXPECT( [store[filename] stringValue], @"Browser test content", @"dropped succsefully");
    unlink( filenametemplate);
}


+(NSArray*)testSelectors
{
    return @[
             @"testDroppingStuff",
             ];
}

@end
