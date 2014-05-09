//
//  MOBTileOverlay.m
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "MOBTileOverlay.h"

#import "MapLayer.h"

@interface MOBTileOverlay  ()

@property NSCache *cache;
@property NSOperationQueue *operationQueue;

@end

@implementation MOBTileOverlay

- (id)initWithMapLayer:(MapLayer *)mapLayer
{
    if (self = [self initWithURLTemplate:mapLayer.o_urlTile]) {
        _mapLayer = mapLayer;
    }
    return self;
}

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *data, NSError *error))result
{
    if (!result) {
        return;
    }
    
    
   __block NSString *cachePath = [self.mapLayer cacheMapPath:path];
    
    NSData *cachedData = [NSData dataWithContentsOfFile:cachePath];
    if (cachedData) {
        result(cachedData, nil);
    }
    

        NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            

            NSError *error;
            [data writeToFile:cachePath options:NSDataWritingAtomic error:&error];
//            if (error) {
//                NSLog(@"error %@", [error debugDescription]);
//            }            
            result(data, connectionError);
        }];
}

@end
