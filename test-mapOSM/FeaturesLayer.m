//
//  FeaturesLayer.m
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "FeaturesLayer.h"
#import "Feature.h"


@implementation FeaturesLayer

@dynamic o_title;
@dynamic o_text;
@dynamic o_source;
@dynamic o_isActive;
@dynamic o_id;
@dynamic features;

+ (instancetype)layerWithId:(NSString *)xid
{
    return [[MOBDataManager sharedManager] createEntity:@"FeaturesLayer" withIdName:@"o_id" withIdValue:xid];
}

+ (RACSignal *)reloadData
{
    return  [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber){
        [subscriber sendNext:nil];
        [subscriber sendCompleted];
        
        return [RACDisposable disposableWithBlock:^{
            //                        [dataTask cancel];
        }];
    }];
}

#pragma mark -
- (void)selectFeatureLayer:(BOOL)active
{
    self.o_isActive = active;
    [[MOBDataManager sharedManager] saveContext];
}

#pragma mark - MOBManagedObjectSerialization
- (void)managedObjectPopulate:(NSDictionary *)data
{
    self.o_title = data[@"title"];
}

@end
