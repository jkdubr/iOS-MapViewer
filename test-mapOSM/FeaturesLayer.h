//
//  FeaturesLayer.h
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Feature;

@interface FeaturesLayer : NSManagedObject<MOBManagedObjectSerialization>

@property (nonatomic, retain) NSString * o_title;
@property (nonatomic, retain) NSString * o_text;
@property (nonatomic, retain) NSString * o_id;
@property (nonatomic, retain) NSString * o_source;
@property (nonatomic) BOOL o_isActive;
@property (nonatomic, retain) NSSet *features;

+ (RACSignal *) reloadData;

+ (instancetype) layerWithId: (NSString *) xid;

- (void) selectFeatureLayer:(BOOL) active;


@end

@interface FeaturesLayer (CoreDataGeneratedAccessors)

- (void)addFeaturesObject:(Feature *)value;
- (void)removeFeaturesObject:(Feature *)value;
- (void)addFeatures:(NSSet *)values;
- (void)removeFeatures:(NSSet *)values;

@end
