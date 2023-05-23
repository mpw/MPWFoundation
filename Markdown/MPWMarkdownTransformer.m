//
//  MPWMarkdownTransformer.m
//  SiteBuilding
//
//  Created by Marcel Weiher on 21.04.23.
//

#import "MPWMarkdownTransformer.h"
#import "NSDataMarkdown.h"
#import "markdown.h"
#import "html.h"

#define OUTPUT_UNIT 64

@implementation MPWMarkdownTransformer
{
    struct sd_callbacks callbacks;
    struct html_renderopt options;
    struct sd_markdown *markdown;
}

-(instancetype)initWithTarget:(id)aTarget
{
    self=[super initWithTarget:aTarget];
    sdhtml_renderer(&callbacks, &options, 0);
    markdown = sd_markdown_new(0, 16, &callbacks, &options);
    return self;
}

-(void)writeData:(NSData *)d
{
    struct buf *ob = bufnew(OUTPUT_UNIT);
    sd_markdown_render(ob, [d bytes], [d length], markdown);
    [self appendBytes:ob->data length:ob->size];
    bufrelease(ob);
}

-(void)writeString:(NSString *)aString
{
    [self writeData:[aString asData]];
}

-(void)dealloc
{
    sd_markdown_free(markdown);
    [super dealloc];
}

@end


#import <MPWFoundation/DebugMacros.h>

@implementation MPWMarkdownTransformer(testing) 

+_processString:aString
{
    return [[self process:aString] stringValue];
}

+(void)testBasicMarkdownTextProcessed
{
    IDEXPECT([self _processString:@"This is some text"],@"<p>This is some text</p>\n",@"plain text");
    IDEXPECT([self _processString:@"This is *emphasized*"],@"<p>This is <em>emphasized</em></p>\n",@"emphasized text");
}

+(void)testCanWriteMarkdownIncrementally
{
    MPWMarkdownTransformer *t=[self stream];
    [t writeObject:@"Some plain text\n\n"];
    [t writeObject:@"*Emphasized* text\n"];
    [t writeObject:@"\nHeadline\n-------\n\n"];
    [t writeObject:@"\n[Link](http://example.com)\n"];
    [t.target writeToFile:@"/tmp/incremental-markdown.html" atomically:YES];
    IDEXPECT(t.target.stringValue, @"<p>Some plain text</p>\n<p><em>Emphasized</em> text</p>\n<h2>Headline</h2>\n<p><a href=\"http://example.com\">Link</a></p>\n",@"incremental");
}

+(NSArray*)testSelectors
{
   return @[
       @"testBasicMarkdownTextProcessed",
       @"testCanWriteMarkdownIncrementally",
			];
}

@end
