/* MPWStream.h Copyright (c) 1998-2015 by Marcel Weiher, All Rights Reserved.


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

*/


#import <Foundation/Foundation.h>
#import "AccessorMacros.h"
#import "MPWObject.h"


@protocol Streaming

-(void)writeObject:anObject;

@end

@interface NSObject(MPWStreaming)

-(void)writeOnStream:(id <Streaming>)aStream;

@end

#define	FORWARD(object)	if ( targetWriteObject ) { targetWriteObject( target, @selector(writeObject:sender:), object ,self); } else { [target writeObject:object sender:self]; }

@interface MPWStream : NSObject <Streaming>
{
    id	target;
    SEL streamWriterMessage;
    IMP0	targetWriteObject;
    id	pad[4];
}

idAccessor_h( target, setTarget )

+streamWithObject:anObject;
+process:anObject;
+(void)processAndIgnore:anObject;
-(void)insertStream:aStream;
-(void)writeNSObject:anObject;
-(void)writeObjectAndClose:anObject;
-(void)writeEnumerator:e spacer:spacer;
-(void)writeEnumerator:e;
-(void)writeData:(NSData*)d;
+streamWithTarget:aTarget;
+stream;
-initWithTarget:aTarget;
+defaultTarget;
-(void)setFinalTarget:newTarget;

-(SEL)streamWriterMessage;
-(void)close;
-(void)flush;
-result;
-finalTarget;

-(void)closeLocal;
-(void)flushLocal;

-(void)reportError:(NSError*)error;

-parseJSONWithKey:(NSString*)key;
-dict2objWithClass:(Class)targetClass selector:(SEL)creationSelector;
-dict2objWithClass:(Class)targetClass; 
-onMainThreadStream;
-onBlock:aBlock;
-(int)inflightCount;


@end

@interface NSObject(BaseStreaming)

-(void)writeOnMPWStream:(MPWStream*)aStream;
@end


@interface NSMutableArray(StreamTarget) <Streaming>

@end

