//
//  Feature.h
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@import MapKit;
@class FeaturesLayer;

@interface Feature : NSManagedObject<MKAnnotation>

@property (nonatomic, retain) NSString * o_title;
@property (nonatomic, retain) NSString * o_text;
@property (nonatomic) double o_lat;
@property (nonatomic) double o_lon;
@property (nonatomic, retain) FeaturesLayer *layer;
@property (nonatomic, retain) NSSet *tag;

+ (instancetype) feature;

@end

@interface Feature (CoreDataGeneratedAccessors)

- (void)addTagObject:(NSManagedObject *)value;
- (void)removeTagObject:(NSManagedObject *)value;
- (void)addTag:(NSSet *)values;
- (void)removeTag:(NSSet *)values;

@end
