//
//  MOBTileOverlay.m
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "MOBTileOverlay.h"

@interface MOBTileOverlay  ()

@property NSCache *cache;
@property NSOperationQueue *operationQueue;

@end

@implementation MOBTileOverlay




/*
- (NSURL *)URLForTilePath:(MKTileOverlayPath)path {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://tile.openstreetmap.org/%d/%d/%d.png", path.z, path.x, path.y]];
}
*/
+ (NSString *) cacheMapPath:(MKTileOverlayPath)path
{

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:[NSString stringWithFormat:@"/map/%d-%d-%d.png", path.z, path.x, path.y]];
}
/*
- (NSMutableArray *)tilesInMapRect:(MKMapRect)rect zoomScale:(MKZoomScale)scale
{
    
    NSInteger z = [self zoomLevel];
    
    NSInteger minX = floor((MKMapRectGetMinX(rect) * scale) / TILE_SIZE);
    NSInteger maxX = floor((MKMapRectGetMaxX(rect) * scale) / TILE_SIZE);
    NSInteger minY = floor((MKMapRectGetMinY(rect) * scale) / TILE_SIZE);
    NSInteger maxY = floor((MKMapRectGetMaxY(rect) * scale) / TILE_SIZE);
    
    NSMutableArray *tiles = nil;
    
    for (NSInteger x = minX; x <= maxX; x++) {
        for (NSInteger y = minY; y <= maxY; y++) {
            
            NSString *tileString = [NSString stringWithFormat:@"z%ix%iy%i",z,x,y];
            if (!tiles) {
                tiles = [NSMutableArray array];
            }
            [tiles addObject:tileString];
        }
    }
    
    return tiles;
}

- (NSUInteger) zoomLevel {
    return (21 - round(log2(self.mapView.region.span.longitudeDelta * MERCATOR_RADIUS * M_PI / (180.0 * self.mapView.bounds.size.width))));
}
*/

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *data, NSError *error))result
{
    if (!result) {
        return;
    }
    
    NSData *cachedData = [self.cache objectForKey:[self URLForTilePath:path]];
    if (cachedData) {
        result(cachedData, nil);
    } else {
        NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            NSString *pathFile = [MOBTileOverlay cacheMapPath:path];
            NSError *error;
            [data writeToFile:pathFile options:NSDataWritingAtomic error:&error];
            if (error) {
                NSLog(@"error %@", [error debugDescription]);
            }
            
            result(data, connectionError);
        }];
    }
}

@end
