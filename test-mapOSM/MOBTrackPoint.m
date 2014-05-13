//
//  MOBTrackPoint.m
//  MapViewer
//
//  Created by Jakub Dubrovsky on 11/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "MOBTrackPoint.h"


@implementation MOBTrackPoint

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate atPosition:(CGFloat)metersFromStart atElevation:(CGFloat)elevation
{
    if (self = [self init]) {
        _coordinate = coordinate;
        _position = metersFromStart;
        _elevation = elevation;
    }
    return self;
}

- (CGFloat)mobGraphPointX
{
    return self.position;
}
- (CGFloat)mobGraphPointY
{
    return self.elevation;
}
@end
