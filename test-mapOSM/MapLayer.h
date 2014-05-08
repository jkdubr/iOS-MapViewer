//
//  MapLayer.h
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MapLayer : NSManagedObject<MOBManagedObjectSerialization>

@property (nonatomic, retain) NSString * o_title;
@property (nonatomic, retain) NSString * o_text;
@property (nonatomic, retain) NSString * o_source;
@property (nonatomic, retain) NSString * o_urlTile;
@property (nonatomic, retain) NSString * o_id;
@property (nonatomic) BOOL o_isActive;
@property (nonatomic, retain) NSSet *tag;

+ (RACSignal *) reloadData;

+ (instancetype) mapWithId: (NSString *) xid;
+ (instancetype) activeMapLayer;

- (void) selectMapLayer:(BOOL) active;
@end

@interface MapLayer (CoreDataGeneratedAccessors)

- (void)addTagObject:(NSManagedObject *)value;
- (void)removeTagObject:(NSManagedObject *)value;
- (void)addTag:(NSSet *)values;
- (void)removeTag:(NSSet *)values;

@end
