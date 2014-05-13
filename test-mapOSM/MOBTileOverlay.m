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

//@property NSCache *cache;

@end

@implementation MOBTileOverlay

- (id)initWithMapLayer:(MapLayer *)mapLayer
{
    if (self = [self initWithURLTemplate:mapLayer.o_urlTile]) {
        _mapLayer = mapLayer;
//        self.cache = [[NSCache alloc] init];
    }
    return self;
}

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *data, NSError *error))result
{
    if (!result) {
        return;
    }
    
    __block NSString *cachePath = [self.mapLayer cacheMapPath:path];
    
    /*
    NSData *cachedData = [self.cache objectForKey:cachePath];
    if (cachedData) {
      //  NSLog(@"cache memory");
        result(cachedData, nil);
    }else{
        */
        NSData *cachedData = [NSData dataWithContentsOfFile:cachePath];
        if (cachedData) {
      //      [self.cache setObject:cachedData forKey:cachePath];
         //   NSLog(@"cache file");
            result(cachedData, nil);
        }else{
            
            NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                
                
                NSError *error;
                [data writeToFile:cachePath options:NSDataWritingAtomic error:&error];
                //            if (error) {
                //                NSLog(@"error %@", [error debugDescription]);
                //            }

                /*     if (data) {
                    [self.cache setObject:data forKey:cachePath];
                }
*/
                 
              //  NSLog(@"cache url");
                
                result(data, connectionError);
            }];
        }
  //  }
}

@end
