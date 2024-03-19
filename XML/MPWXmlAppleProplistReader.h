/* MPWXmlAppleProplistReader.h Copyright (c) Marcel P. Weiher 1999-2006, All Rights Reserved,
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
THE POSSIBILITY OF SUCH DAMAGE.

, created  on Tue 20-Jul-1999 */

#import <MPWFoundation/MPWMAXParser.h>

@interface MPWXmlAppleProplistReader : MPWMAXParser
{
	const void *allocator;
	id true_value,false_value;
}

@property (nonatomic, assign) bool isMutable;


-realElement:(const char*)start length:(long)len __attribute((ns_returns_retained));
-integerElement:(id <NSXMLAttributes>)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser __attribute((ns_returns_retained));
-dictElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser __attribute((ns_returns_retained));
-arrayElement:(MPWXMLAttributes*)children attributes:(id <NSXMLAttributes>)attrs parser:(MPWMAXParser*)parser __attribute((ns_returns_retained));
-integerElementAtPtr:(const char*)start length:(long)len __attribute((ns_returns_retained));

@end
