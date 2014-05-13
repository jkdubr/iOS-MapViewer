//
//  MOBGraphLineView.m
//  MyGraph
//
//  Created by Jakub Dubrovsky on 11/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "MOBGraphLineView.h"


@implementation MOBGraphLineView

#define kGraphHeight 300
#define kDefaultGraphWidth 900
#define kOffsetX 10
#define kStepX 50
#define kGraphBottom 300
#define kGraphTop 0

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    
    CGFloat xMax=0;
    CGFloat yMax=0;
        CGFloat yMin=0;
    NSMutableArray *data = [[NSMutableArray alloc] initWithCapacity:[self.delegate mobGraphLineNumberOfItems:self]];
    for (NSUInteger i = 0; i<[self.delegate mobGraphLineNumberOfItems:self]; i++) {
        id<MOBGraphPointDelegate> obj = [self.delegate mobGraph:self pointAtPosition:i];
        xMax = MAX(xMax, [obj mobGraphPointX]);
        yMax = MAX(yMax, [obj mobGraphPointY]);
                yMin = MIN(yMin, [obj mobGraphPointY]);
        [data addObject:obj];
    }
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(ctx, 1.6);
    CGContextSetStrokeColorWithColor(ctx, [[UIColor lightGrayColor] CGColor]);
    

    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 0,0);
    
    CGFloat height = yMax - yMin + (0.1 * (yMax - yMin));
    
    for (NSUInteger i = 0; i<[self.delegate mobGraphLineNumberOfItems:self]; i++) {
        id<MOBGraphPointDelegate> obj = [self.delegate mobGraph:self pointAtPosition:i];
        
        if (i==0) {
            CGContextMoveToPoint(ctx, ([obj mobGraphPointX] / xMax)*self.frame.size.width, ([obj mobGraphPointY] / height) *self.frame.size.height);
        }else{
            CGContextAddLineToPoint(ctx, ([obj mobGraphPointX] / xMax)*self.frame.size.width, ([obj mobGraphPointY] / height) *self.frame.size.height);
        }
    }

    
    CGContextDrawPath(ctx, kCGPathStroke);
}
@end
