//
//  MapLayer.m
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "MapLayer.h"


@implementation MapLayer

@dynamic o_title;
@dynamic o_text;
@dynamic o_source;
@dynamic o_urlTile;
@dynamic o_isActive;
@dynamic o_id;
@dynamic tag;



+ (instancetype)mapWithId:(NSString *)xid
{
    return [[MOBDataManager sharedManager] createEntity:@"MapLayer" withIdName:@"o_id" withIdValue:xid];
}

+ (instancetype)activeMapLayer
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MapLayer"];
    
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"o_isActive = %@", @(YES)];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[[MOBDataManager sharedManager] managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count) {
        return fetchedObjects[0];
    }
    return nil;
}

+ (RACSignal *)reloadData
{
    return  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber){
        //http://www.neongeo.com/wiki/doku.php?id=map_servers
        NSArray *temp = @[
                          @{
                              @"url" : @"http://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              @"title" : @"OSM",
                              @"id" : @"osm1"
                              },
                          @{
                              @"url" : @"http://c.tile.thunderforest.com/cycle/{z}/{x}/{y}.png",
                              @"title" : @"OSM Cyclo",
                              @"id" : @"osmcyclo"
                              },
                          @{
                              @"url" : @"http://mt0.google.com/vt/x={x}&y={y}&z={z}",
                              @"title" : @"Google 1",
                              @"id" : @"google1"
                              },
                          @{
                              @"url" : @"http://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}",
                              @"title" : @"Google Hybrid",
                              @"id" : @"googleh"
                              }
                          ];
        
        //
        
        for (NSDictionary *dic in temp) {
            MapLayer *mapLayer = [MapLayer mapWithId:dic[@"id"]];
            [mapLayer managedObjectPopulate:dic];
        }
        
        [subscriber sendNext:nil];
        [subscriber sendCompleted];
        
        return [RACDisposable disposableWithBlock:^{
            //                        [dataTask cancel];
        }];
    }];
}

#pragma mark - cache


- (RACSignal *) cacheDownloadRegion: (MKCoordinateRegion) region zoomMin:(NSUInteger) zoomMin zoomMax: (NSUInteger) zoomMax
{
    return  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        
        dispatch_async(queue, ^{
            
            CLLocationCoordinate2D center = region.center;
            CLLocationCoordinate2D northWestCorner, southEastCorner;
            northWestCorner.latitude  = center.latitude  + (region.span.latitudeDelta  / 2.0);
            northWestCorner.longitude = center.longitude - (region.span.longitudeDelta / 2.0);
            southEastCorner.latitude  = center.latitude  - (region.span.latitudeDelta  / 2.0);
            southEastCorner.longitude = center.longitude + (region.span.longitudeDelta / 2.0);
            
            
            NSUInteger tilesAll =0;
            for (NSUInteger zoom=1; zoom<zoomMax; zoom++) {
                int x1 = long2tilex(northWestCorner.longitude, zoom);
                int x2 = long2tilex(southEastCorner.longitude, zoom);
                int y1 = lat2tiley(northWestCorner.latitude, zoom);
                int y2 = lat2tiley(southEastCorner.latitude, zoom);
                
                tilesAll += (x2-x1) * (y2-y1) * zoomMax;
            }
            
            
            NSUInteger tilesDone = 0;
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
            
            for (NSUInteger zoom=zoomMin; zoom<=zoomMax; zoom++) {
                int x1 = long2tilex(northWestCorner.longitude, zoom);
                int x2 = long2tilex(southEastCorner.longitude, zoom);
                int y1 = lat2tiley(northWestCorner.latitude, zoom);
                int y2 = lat2tiley(southEastCorner.latitude, zoom);
                
                NSLog(@"zoom %i x: %i - %i = %i y: %i - %i = %i",zoom,x1,x2,x1-x2,y1,y2,y1-y2);
                
                
                for (NSUInteger y = y1; y <= y2; y++) {
                    for (NSUInteger x = x1; x <= x2; x++) {
                        tilesDone++;
                        
                        NSData *data = [NSData dataWithContentsOfURL:[self urlTileAtX:x atY:y atZoom:zoom]];
                        if (!data) {
                            NSLog(@"err data ");
                            //                 return ;
                        }
                        
                        NSString *pathFile =  [basePath stringByAppendingString:[NSString stringWithFormat:@"/map/%@/%d-%d-%d.png", self.o_id,zoom, x, y]];
                        
                        NSError *error;
                        [data writeToFile:pathFile options:NSDataWritingAtomic error:&error];
                        if (error) {
                            [subscriber sendError:error];
                            [subscriber sendCompleted];

                            return ;
                        }
                    }
                }
            }
            
            
            
            
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                // Update UI
                // Example:
                // self.myLabel.text = result;
                [subscriber sendNext:nil];
                [subscriber sendCompleted];
            });
        });
        
        return nil;
    }];
    
}
- (NSString *)cacheMapPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/map/%@", self.o_id]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:NULL]; //Create folder
    
    return dataPath;
}
- (NSString *) cacheMapPath:(MKTileOverlayPath)path
{
    return [[self cacheMapPath] stringByAppendingString:[NSString stringWithFormat:@"/%d-%d-%d.png", path.z, path.x, path.y]];
}

- (RACSignal *)cacheSize
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber){
        
        NSString *folderPath = [self cacheMapPath];
        
        NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
        NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
        NSString *fileNames;
        unsigned long long int fileSize = 0;
        //fileSize = 0;
        
        while (fileNames = [filesEnumerator nextObject]) {
            NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileNames] error:nil];
            fileSize += [fileDictionary fileSize];
        }
        NSLog(@"filesize==%llu",fileSize);
        
        fileSize = ((float)fileSize) / (1024*1024);
        
        [subscriber sendNext:[NSNumber numberWithFloat:fileSize]];
        [subscriber sendCompleted];
        return nil;
    }];
}

- (RACSignal *)cacheReset
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber){
        NSString *folderPath = [self cacheMapPath];
        
        NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
        NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
        NSString *fileNames;
        
        while (fileNames = [filesEnumerator nextObject]) {
            NSString *fileName = [folderPath stringByAppendingString:[NSString stringWithFormat: @"/%@", fileNames]];
            if (![[NSFileManager defaultManager] removeItemAtPath:fileName error:NULL]) {
                NSLog(@"[Error] %@ ", fileName);
            }
        }
        [subscriber sendNext:nil];
        [subscriber sendCompleted];
        return nil;
    }];
}
#pragma mark -
- (NSURL *) urlTileAtX: (NSUInteger) x atY:(NSUInteger) y atZoom:(NSUInteger) zoom{
    NSString *string = [[[self.o_urlTile stringByReplacingOccurrencesOfString:@"{x}" withString:[NSString stringWithFormat:@"%i", x]] stringByReplacingOccurrencesOfString:@"{y}" withString:[NSString stringWithFormat:@"%i", y]] stringByReplacingOccurrencesOfString:@"{z}" withString:[NSString stringWithFormat:@"%i", zoom]];
    NSURL *url = [NSURL URLWithString:string];
    return url;
}
- (void)selectMapLayer:(BOOL)active
{
    if (active) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MapLayer"];
        for (MapLayer *mapLayer in [[[MOBDataManager sharedManager] managedObjectContext] executeFetchRequest:fetchRequest error:NULL]) {
            [mapLayer setO_isActive:NO];
        }
    }
    
    self.o_isActive = active;
    [[MOBDataManager sharedManager] saveContext];
}

#pragma mark - MOBManagedObjectSerialization
- (void)managedObjectPopulate:(NSDictionary *)data
{
    self.o_urlTile = data[@"url"];
    self.o_title = data[@"title"];
}
@end
