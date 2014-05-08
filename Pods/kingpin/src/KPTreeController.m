//
// Copyright 2012 Bryan Bonczek
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "KPTreeController.h"

#import "KPAnnotation.h"
#import "KPAnnotationTree.h"

#import "NSArray+KP.h"

@interface KPTreeController()

@property (nonatomic) MKMapView *mapView;
@property (nonatomic) KPAnnotationTree *annotationTree;
@property (nonatomic) MKMapRect lastRefreshedMapRect;
@property (nonatomic) MKCoordinateRegion lastRefreshedMapRegion;
@property (nonatomic) CGRect mapFrame;

@end

@implementation KPTreeController

- (id)initWithMapView:(MKMapView *)mapView {
    
    self = [super init];
    
    if(self){
        self.mapView = mapView;
        self.mapFrame = self.mapView.frame;
        self.gridSize = CGSizeMake(60.f, 60.f);
        self.animationDuration = 0.5f;
    }
    
    return self;
    
}

- (void)setAnnotations:(NSArray *)annotations {
    [self.mapView removeAnnotations:[self.annotationTree.annotations allObjects]];
    self.annotationTree = [[KPAnnotationTree alloc] initWithAnnotations:annotations];
    [self _updateVisibileMapAnnotationsOnMapView:NO];
}

- (void)refresh:(BOOL)animated {
    
    if(MKMapRectIsNull(self.lastRefreshedMapRect) || [self _mapWasZoomed] || [self _mapWasPannedSignificantly]){
        [self _updateVisibileMapAnnotationsOnMapView:animated && [self _mapWasZoomed]];
        self.lastRefreshedMapRect = self.mapView.visibleMapRect;
        self.lastRefreshedMapRegion = self.mapView.region;
    }
}

// only refresh if:
// - the map has been zoomed
// - the map has been panned significantly

- (BOOL)_mapWasZoomed {
    return (fabs(self.lastRefreshedMapRect.size.width - self.mapView.visibleMapRect.size.width) > 0.1f);
}

- (BOOL)_mapWasPannedSignificantly {
    CGPoint lastPoint = [self.mapView convertCoordinate:self.lastRefreshedMapRegion.center
                                          toPointToView:self.mapView];
    
    CGPoint currentPoint = [self.mapView convertCoordinate:self.mapView.region.center
                                             toPointToView:self.mapView];
    
    
    return
    (fabs(lastPoint.x - currentPoint.x) > self.mapFrame.size.width) ||
    (fabs(lastPoint.y - currentPoint.y) > self.mapFrame.size.height);
}


#pragma mark - Private

- (void)_updateVisibileMapAnnotationsOnMapView:(BOOL)animated
{
    
    NSSet *visibleAnnotations = [self.mapView annotationsInMapRect:[self.mapView visibleMapRect]];
    
    // we initialize with a rough estimate for size, as to minimize allocations
    NSMutableArray *newClusters = [[NSMutableArray alloc] initWithCapacity:visibleAnnotations.count * 2];
    
    // updates visible map rect plus a map view's worth of padding around it
    MKMapRect bigRect = MKMapRectInset(self.mapView.visibleMapRect,
                                       -self.mapView.visibleMapRect.size.width,
                                       -self.mapView.visibleMapRect.size.height);
    
    // calculate the grid size in terms of MKMapPoints
    double widthPercentage = self.gridSize.width / CGRectGetWidth(self.mapView.frame);
    double heightPercentage = self.gridSize.height / CGRectGetHeight(self.mapView.frame);
    
    double widthInterval = ceil(widthPercentage * self.mapView.visibleMapRect.size.width);
    double heightInterval = ceil(heightPercentage * self.mapView.visibleMapRect.size.height);
    
    for(int x = bigRect.origin.x; x < bigRect.origin.x + bigRect.size.width; x += widthInterval){
        
        for(int y = bigRect.origin.y; y < bigRect.origin.y + bigRect.size.height; y += heightInterval){
            
            MKMapRect gridRect = MKMapRectMake(x, y, widthInterval, heightInterval);

            NSArray *newAnnotations = [self.annotationTree annotationsInMapRect:gridRect];
            
            // cluster annotations in this grid piece, if there are annotations to be clustered
            if(newAnnotations.count){

                KPAnnotation *a = [[KPAnnotation alloc] initWithAnnotations:newAnnotations];
                
                if([self.delegate respondsToSelector:@selector(treeController:configureAnnotationForDisplay:)]){
                    [self.delegate treeController:self configureAnnotationForDisplay:a];
                }
                
                [newClusters addObject:a];
            }
        }
    }
    
    NSArray *oldClusters = [[[self.mapView annotationsInMapRect:bigRect] allObjects] kp_filter:^BOOL(id annotation) {
        
        if([annotation isKindOfClass:[KPAnnotation class]]){
            return ([self.annotationTree.annotations containsObject:[[(KPAnnotation*)annotation annotations] anyObject]]);
        }
        else {
            return NO;
        }
    }];
    
    if(animated){
        
        for(KPAnnotation *newCluster in newClusters){
            
            [self.mapView addAnnotation:newCluster];
            
            // if was part of an old cluster, then we want to animate it from the old to the new (spreading animation)
            
            for(KPAnnotation *oldCluster in oldClusters){
                
                if([oldCluster.annotations member:[newCluster.annotations anyObject]]){
                    
                    if([visibleAnnotations member:oldCluster]){
                        [self _animateCluster:newCluster
                               fromCoordinate:oldCluster.coordinate
                                 toCoordinate:newCluster.coordinate
                                   completion:nil];
                    }
                    
                    [self.mapView removeAnnotation:oldCluster];
                }
                
                // if the new cluster had old annotations, then animate the old annotations to the new one, and remove it
                // (collapsing animation)
                
                else if([newCluster.annotations member:[oldCluster.annotations anyObject]]){
                    
                    if(MKMapRectContainsPoint(self.mapView.visibleMapRect, MKMapPointForCoordinate(newCluster.coordinate))){
                        [self _animateCluster:oldCluster
                               fromCoordinate:oldCluster.coordinate
                                 toCoordinate:newCluster.coordinate
                                   completion:^(BOOL finished) {
                                       [self.mapView removeAnnotation:oldCluster];
                                   }];
                    }
                    else {
                        [self.mapView removeAnnotation:oldCluster];
                    }
                    
                }
            }
        }

    }
    else {
        [self.mapView removeAnnotations:oldClusters];
        [self.mapView addAnnotations:newClusters];
    }
        
}

- (void)_animateCluster:(KPAnnotation *)cluster
         fromCoordinate:(CLLocationCoordinate2D)fromCoord
           toCoordinate:(CLLocationCoordinate2D)toCoord
             completion:(void (^)(BOOL finished))completion
{
    
    cluster.coordinate = fromCoord;
    
    [UIView animateWithDuration:self.animationDuration
                          delay:0.f
                        options:self.animationOptions
                     animations:^{
                         cluster.coordinate = toCoord;
                     }
                     completion:completion];
    
}


@end
