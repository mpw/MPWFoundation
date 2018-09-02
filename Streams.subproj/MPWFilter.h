//
//  MPWFilter.h
//  MPWFoundation
//
//  Created by Marcel Weiher on 9/2/18.
//

#import <MPWFoundation/MPWStream.h>


typedef id (*IMP_2_id_args)(id, SEL, id,id);


#define    FORWARD(object)    if (  targetWriteObject ) { targetWriteObject( _target, @selector(writeObject:sender:), object ,self); } else { [_target writeObject:object sender:self]; }


@interface MPWFilter : MPWStream
{
    id _target;
    IMP_2_id_args    targetWriteObject;
}

@property (nonatomic, strong)  IBOutlet MPWStream *target;

+(instancetype)streamWithTarget:aTarget;
-(instancetype)initWithTarget:aTarget;

-(void)flush:(int)n;
-(void)close:(int)n;

-(void)setFinalTarget:newTarget;
-(void)forward:anObject;
-finalTarget;

+defaultTarget;

-(void)insertStream:aStream;

-firstObject;       // dummy for testing

@end
