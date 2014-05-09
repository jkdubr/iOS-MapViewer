//
//  MOBTileOverlay.h
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MOBTileOverlay : MKTileOverlay

@property(nonatomic, strong) NSString *o_id;
- (id)initWithURLTemplate:(NSString *)URLTemplate amdWithId:(NSString *) xid;
@end
