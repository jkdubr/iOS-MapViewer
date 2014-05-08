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
                              }
                          ];
        
        
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

#pragma mark -
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
