//
//  MOBMapViewController.h
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import <UIKit/UIKit.h>

@import MapKit;
@import CoreLocation;

#import "KPTreeController.h"

@interface MOBMapViewController : UIViewController<MKMapViewDelegate, CLLocationManagerDelegate,KPTreeControllerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;


@end
