//
//  Feature.m
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "Feature.h"


@implementation Feature

@dynamic o_title;
@dynamic o_text;
@dynamic o_lat;
@dynamic o_lon;
@dynamic layer;
@dynamic tag;

+ (instancetype)feature
{
    return [[MOBDataManager sharedManager] createEntity:@"Feature" withIdName:nil withIdValue:nil];
}

#pragma mark - MKAnnotation
- (NSString *)title
{
    return self.o_title;
}

- (NSString *)subtitle
{
    return self.o_text;
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.o_lat, self.o_lon);
}
@end
