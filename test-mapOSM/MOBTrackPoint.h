//
//  MOBTrackPoint.h
//  MapViewer
//
//  Created by Jakub Dubrovsky on 11/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

#import "MOBGraphLineView.h"

@interface MOBTrackPoint : NSObject<MOBGraphPointDelegate>

@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly) CGFloat position;
@property(nonatomic, readonly) CGFloat elevation;

- (instancetype) initWithCoordinate: (CLLocationCoordinate2D) coordinate atPosition:(CGFloat) metersFromStart atElevation: (CGFloat) elevation;
@end
