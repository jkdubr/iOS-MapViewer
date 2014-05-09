//
//  MOBTileOverlay.h
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import <MapKit/MapKit.h>

@class MapLayer;

@interface MOBTileOverlay : MKTileOverlay

@property(nonatomic, strong, readonly) MapLayer *mapLayer;

- (id)initWithMapLayer:(MapLayer *) mapLayer;

@end
