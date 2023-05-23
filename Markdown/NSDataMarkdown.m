//
//  NSDataMarkdown.m
//  WebSiteObjC
//
//  Created by Marcel Weiher on 12/23/12.
//
//


#import "markdown.h"
#import "html.h"

#import "NSDataMarkdown.h"

@implementation NSData(Markdown)

#define OUTPUT_UNIT 64


-markdownToHtml
{
    struct sd_callbacks callbacks;
    struct html_renderopt options;
    struct sd_markdown *markdown;

    struct buf *ob;
    /* performing markdown parsing */
    ob = bufnew(OUTPUT_UNIT);
    
    sdhtml_renderer(&callbacks, &options, 0);
    markdown = sd_markdown_new(0, 16, &callbacks, &options);
    
    sd_markdown_render(ob, [self bytes], [self length], markdown);
    sd_markdown_free(markdown);
    
    /* writing the result to stdout */
    
    NSData *html=[NSData dataWithBytes:ob->data length:ob->size];
    bufrelease(ob);

    return html;

}

@end

@implementation NSString(markdown)

-markdownToHtml
{
    return [[[NSString alloc] initWithData:[[self asData] markdownToHtml] encoding:NSUTF8StringEncoding] autorelease];
}

@end

@implementation NSObject(markdown)

-markdownToHtml {
    NSLog(@"markdownToHtml: %@:%@",[self class],self);
    return self;
}

@end

