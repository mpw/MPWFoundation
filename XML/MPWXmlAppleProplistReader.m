/* MPWXmlAppleProplistReader.m Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

        Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.

        Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in
        the documentation and/or other materials provided with the distribution.

        Neither the name Marcel Weiher nor the names of contributors may
        be used to endorse or promote products derived from this software
        without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.  */

#import "MPWXmlAppleProplistReader.h"
#import "MPWXmlAttributes.h"
#import "MPWMAXParser_private.h"
#import "MPWSubData.h"
#import "NSBundleConveniences.h"

@implementation MPWXmlAppleProplistReader


-init
{
    self = [super init];
#ifndef GNUSTEP
	allocator = kCFAllocatorSystemDefault; // CFAllocatorGetDefault();
#endif
	true_value = [[NSNumber numberWithBool:YES] retain];
	false_value = [[NSNumber numberWithBool:NO] retain];
	[self setHandler:self forElements:[NSArray arrayWithObjects:@"key",@"string",@"date",@"data",@"dict",@"array",@"integer",@"real",@"true",@"false",@"plist",nil]];


	return self;
}



-arrayElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser
{
	
	return [[children allValues] retain];
}


-defaultElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser  __attribute((ns_returns_retained))
{
	return [[children lastObject] retain];
}

-dictElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser
{    
	id *objs=[children _pointerToObjects];
	long count=[children count];
	id keys[count/2+1],values[count/2+1];
	int i;
	for (i=0;i<count/2;i++) {
		keys[i]=[NSString stringWithString:objs[i*2]];
		values[i]=objs[i*2+1];
	}
	return [[NSDictionary alloc] initWithObjects:values forKeys:keys count:count/2];
}

-integerElementAtPtr:(const char*)start length:(long)len
{
	int val=0;
	int sign=1;
	const char *end=start+len;
	if ( start[0] =='-' ) {
		sign=-1;
		start++;
	} else if ( start[0]=='+' ) {
		start++;
	}
	while ( start < end && isdigit(*start)) {
		val=val*10+ (*start)-'0';
		start++;
	}
	val*=sign;
#ifndef GNUSTEP
	return (id)CFNumberCreate( allocator, kCFNumberSInt32Type, &val );
#else
    return [[NSNumber numberWithInt:val] retain];
#endif
}

-realElement:(const char*)start length:(long)len
{
	double val=0;
	double sign=1;
	const char *end=start+len;
	if ( start[0] =='-' ) {
		sign=-1.0;
		start++;
	} else if ( start[0]=='+' ) {
		start++;
	}
	while ( start < end && isdigit(*start)) {
		val=val*10+ (*start)-'0';
		start++;
	}
	if ( start < end && *start == '.' ) {
		double fraction=0.1;
		start++;
		while ( start < end && isdigit(*start)) {
			val=val + ((*start)-'0')*fraction;
			start++;
			fraction*=0.1;
		}
	}
	val*=sign;
#ifndef GNUSTEP
    return (id)CFNumberCreate( allocator, kCFNumberDoubleType, &val );
#else
    return [[NSNumber numberWithDouble:val] retain];
#endif
}

-integerElement:(id <NSXMLAttributes>)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser
{
	id subdata=[children lastObject];
	return [self integerElementAtPtr:[subdata bytes] length:[subdata length]];
}

-stringElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser  __attribute((ns_returns_retained))
{
	id result=nil;
	long count=[children count];
	if ( count == 1 ) {
		result = [[children lastObject] retain];
	} else {
		int i;
		id *strings = (id*)[children _pointerToObjects];
		result = [[NSMutableString alloc] initWithString:strings[0]];
		for ( i=1;i<count;i++ ) {
			[result appendString:strings[i]];
		}
	}
	return result;
}

-dataElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser  __attribute((ns_returns_retained))
{
	return [self stringElement:children attributes:attrs parser:parser];
}


-realElement:(id <NSXMLAttributes>)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser  __attribute((ns_returns_retained))
{
	return [self integerElement:children attributes:attrs parser:parser];
}

-dateElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser
{
//    id dateString = [children lastObject];
//    long len=[dateString length];
//    CFGregorianDate date;
//    char temp[ len+1];
//    int year,month,day,hour,minute,second;
//    memcpy(temp,[dateString bytes],len);
//    temp[len]=0;
//    sscanf( temp, "%d-%d-%dT%d:%d:%dZ",&year,&month,&day,&hour,&minute,&second);
//    date.year=year;
//    date.month=month;
//    date.day=day;
//    date.hour=hour;
//    date.minute=minute;
//    date.second=second;
//    return (id)CFDateCreate( allocator, CFGregorianDateGetAbsoluteTime(date, NULL));
    return nil;
}

-keyElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser  __attribute((ns_returns_retained))
{
    if ( [children count]==1) {
        MPWSubData *d=[children lastObject];
        return [[NSString alloc] initWithBytes:[d bytes] length:[d length] encoding:NSUTF8StringEncoding];
    } else {
        return [self stringElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser];
    }
}

-falseElement:(id <NSXMLAttributes>)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser  __attribute((ns_returns_retained))
{
	return [false_value retain];
}

-trueElement:(id <NSXMLAttributes>)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser  __attribute((ns_returns_retained))
{
	return [true_value retain];
}


-plistElement:(MPWXMLAttributes*) children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser  __attribute((ns_returns_retained))
{
	return [[children lastObject] retain];
}

-(void)dealloc
{
	[true_value release];
	[false_value release];
	[super dealloc];
}



@end

#import "DebugMacros.h"
#import "NSObjectAdditions.h"

@implementation MPWXmlAppleProplistReader(testing)


+(void)testItunesInfoPlist
{
	id parser = [self parser];
	id result;
	[parser parse:[self frameworkResource:@"Itunes_info" category:@"plist"]];
	result = [parser parseResult];
//	NSLog(@"property list result: %@",result);
//	NSLog(@"property list target: %@",[parser target]);
	INTEXPECT( [result count], 23 ,@"items in top level dict" );
	INTEXPECT( [[result objectForKey:@"DummyInteger"] intValue], 42 ,@"my dummy integer" );
	IDEXPECT( [result objectForKey:@"DummyInteger"], [NSNumber numberWithInt:42], @"dummy integer is not a string");
	IDEXPECT( [result objectForKey:@"HIWindowFlushAtFullRefreshRate"], [NSNumber numberWithBool:YES], @"true");
	IDEXPECT( [result objectForKey:@"QuartzGLEnable"], [NSNumber numberWithBool:NO], @"false");
	INTEXPECT( [[result objectForKey:@"CFBundleDocumentTypes"] count], 26 ,@"doc types array size" );

}

+(void)testEmptyElementsPlist
{
	id parser = [self parser];
	id result;
	[parser parse:[self frameworkResource:@"empty_elements" category:@"plist"]];
	result = [parser parseResult];
//    NSLog(@"testEmptyElementsPlist result: %@",result);
	INTEXPECT( (int)[result count], 4 ,@"items in top level dict" );
	INTEXPECT( [[result objectForKey:@"DummyInteger"] intValue], 42 ,@"my dummy integer" );
	IDEXPECT( [result objectForKey:@"DummyInteger"], [NSNumber numberWithInt:42], @"dummy integer is not a string");
	IDEXPECT( [result objectForKey:@"LSRequiresNativeExecution"], [NSNumber numberWithBool:YES], @"true");
	IDEXPECT( [result objectForKey:@"QuartzGLEnable"], [NSNumber numberWithBool:NO], @"false");


}

+testSelectors {
	return [NSArray arrayWithObjects:
		@"testItunesInfoPlist",
		@"testEmptyElementsPlist",
		nil];
}

@end

