//
//  MOBMapViewController.m
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "MOBMapViewController.h"

#import <kingpin/KPTreeController.h>
#import <kingpin/KPAnnotation.h>

#import "MapLayer.h"
#import "FeaturesLayer.h"
#import "Feature.h"

#import "KMLParser.h"
#import "MOBTileOverlay.h"

@interface MOBMapViewController ()

@property(nonatomic, strong) UIBarButtonItem * barButtonLeft;
@property(nonatomic, strong) UIBarButtonItem * barButtonRight;

@property(nonatomic, strong) UISearchBar *searchBar;
@property(nonatomic, strong) IBOutlet UITableView *tableViewSearch;


@property(nonatomic, strong) NSFetchedResultsController * fetchedResultsController;
@property(nonatomic, strong) KPTreeController * treeController;

@property(nonatomic, strong) MOBTileOverlay *mapBasicLayerOverlay;

- (void)loadKMLAtURL:(NSURL *)url;
- (void)didReceiveNewURL:(NSNotification *)notification;

- (IBAction)barButtonRightTouched:(id)sender;
- (IBAction)barButtonLeftTouched:(id)sender;
- (void)searchBarDismiss;

- (void) reloadMap;


@end

@implementation MOBMapViewController


int long2tilex(double lon, int z)
{
	return (int)(floor((lon + 180.0) / 360.0 * pow(2.0, z)));
}

int lat2tiley(double lat, int z)
{
	return (int)(floor((1.0 - log( tan(lat * M_PI/180.0) + 1.0 / cos(lat * M_PI/180.0)) / M_PI) / 2.0 * pow(2.0, z)));
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNewURL:) name:@"MapitoViewerDidReceiveNewURL" object:nil];
    
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Feature"];
    NSSortDescriptor *descriptor1 = [NSSortDescriptor sortDescriptorWithKey:@"o_title" ascending:NO];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"layer.o_isActive = YES"]];
    fetchRequest.sortDescriptors = @[descriptor1];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[[MOBDataManager sharedManager] managedObjectContext]
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    [self.fetchedResultsController setDelegate:self];
    
    
    
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(10.0, 0.0, 200.0, 44.0)];
    [self.searchBar setDelegate:self];
    [self.searchBar setPlaceholder:@"Search POI"];
    [self.searchBar setTranslucent:YES];
    [self.navigationItem setTitleView:self.searchBar];
    
    self.barButtonLeft = [[UIBarButtonItem alloc] initWithTitle:@"Layers" style:UIBarButtonItemStylePlain target:self action:@selector(barButtonLeftTouched:)];
    [self.navigationItem setLeftBarButtonItem:self.barButtonLeft];
    
    [self.tableViewSearch setDelegate:self];
    [self.tableViewSearch setDataSource:self];
    [self.tableViewSearch setHidden:YES];
    
    
    [self.mapView setShowsUserLocation:YES];
    
    self.treeController = [[KPTreeController alloc] initWithMapView:self.mapView];
    self.treeController.delegate = self;
    self.treeController.animationOptions = UIViewAnimationOptionCurveEaseOut;
    
    
    //TODO: for testing purpose
    // NSString *path = [[NSBundle mainBundle] pathForResource:@"aaa" ofType:@"kml"];
    // NSURL *url = [NSURL fileURLWithPath:path];
    //    [self loadKMLAtURL:url];
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:NO];
    
    if (self.mapBasicLayerOverlay) {
        [self.mapView removeOverlay:self.mapBasicLayerOverlay];
    }
    MapLayer *mapLayer = [MapLayer activeMapLayer];
    if (mapLayer) {
        NSLog(@"active map: %@", mapLayer.o_title);
        self.mapBasicLayerOverlay = [[MOBTileOverlay alloc] initWithURLTemplate:mapLayer.o_urlTile amdWithId:mapLayer.o_id]; // (2)
        self.mapBasicLayerOverlay.canReplaceMapContent = YES;					       // (3)
        [self.mapView addOverlay:self.mapBasicLayerOverlay level:MKOverlayLevelAboveLabels];	       // (4)
    }
    
    [self.fetchedResultsController performFetch:nil];
    [self reloadMap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    
    return nil;
}


#pragma mark - user actions
- (void)barButtonLeftTouched:(id)sender
{
    [self performSegueWithIdentifier:@"toLayers" sender:nil];
}
- (void)barButtonRightTouched:(id)sender
{
    if (self.searchBar.isFirstResponder) {
        [self searchBarDismiss];
    }else{
        [self performSegueWithIdentifier:@"toMaps" sender:nil];
    }
}
- (IBAction)actionShare:(UIBarButtonItem *)sender {
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.region = self.mapView.region;
    options.size = self.mapView.frame.size;
    options.scale = [[UIScreen mainScreen] scale];
    
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    
    [snapshotter startWithQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
              completionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
                  if (error) {
                      NSLog(@"[Error] %@", error);
                      return;
                  }
                  
                  MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:nil];
                  
                  UIImage *image = snapshot.image;
                  UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
                  {
                      [image drawAtPoint:CGPointMake(0.0f, 0.0f)];
                      
                      CGRect rect = CGRectMake(0.0f, 0.0f, image.size.width, image.size.height);
                      for (id <MKAnnotation> annotation in self.mapView.annotations) {
                          CGPoint point = [snapshot pointForCoordinate:annotation.coordinate];
                          if (CGRectContainsPoint(rect, point)) {
                              point.x = point.x + pin.centerOffset.x -
                              (pin.bounds.size.width / 2.0f);
                              point.y = point.y + pin.centerOffset.y -
                              (pin.bounds.size.height / 2.0f);
                              [pin.image drawAtPoint:point];
                          }
                      }
                      
                      UIImage *compositeImage = UIGraphicsGetImageFromCurrentImageContext();
                      
                      UIActivityViewController * acv = [[UIActivityViewController alloc] initWithActivityItems:@[compositeImage] applicationActivities:nil];
                      [self presentViewController:acv animated:YES completion:NULL];
                  }
                  UIGraphicsEndImageContext();
              }];
    
    
}
- (IBAction)actionCurrentLocation:(id)sender
{
    if (!self.mapView.showsUserLocation) {
        [self.mapView setShowsUserLocation:YES];
    }
    [self.mapView setCenterCoordinate:self.mapView.userLocation.location.coordinate animated:YES];
}

- (IBAction)actionDownload:(UIBarButtonItem *)sender {
    //TODO: tato metoda by mela byt soucasti MapLayer
    
    //TODO: mela by byt moznost to zastavit - operationqu
    MapLayer *mapLayer = [MapLayer activeMapLayer];
    if (!mapLayer) {
        return;
    }
   // [sender setEnabled:NO];
    
    NSLog(@"active map: %@", mapLayer.o_title);

    

    
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    
    dispatch_async(queue, ^{

        
        
        
        
        MKCoordinateRegion region = self.mapView.region;
        CLLocationCoordinate2D center = region.center;
        CLLocationCoordinate2D northWestCorner, southEastCorner;
        northWestCorner.latitude  = center.latitude  + (region.span.latitudeDelta  / 2.0);
        northWestCorner.longitude = center.longitude - (region.span.longitudeDelta / 2.0);
        southEastCorner.latitude  = center.latitude  - (region.span.latitudeDelta  / 2.0);
        southEastCorner.longitude = center.longitude + (region.span.longitudeDelta / 2.0);
        
        
        NSUInteger maxZoom = 20;
        NSUInteger tilesAll =0;
        for (NSUInteger zoom=1; zoom<maxZoom; zoom++) {
            int x1 = long2tilex(northWestCorner.longitude, zoom);
            int x2 = long2tilex(southEastCorner.longitude, zoom);
            int y1 = lat2tiley(northWestCorner.latitude, zoom);
            int y2 = lat2tiley(southEastCorner.latitude, zoom);
            
            tilesAll += (x2-x1) * (y2-y1) * maxZoom;
        }
        
        
        NSUInteger tilesDone = 0;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        
        for (NSUInteger zoom=1; zoom<maxZoom; zoom++) {
            int x1 = long2tilex(northWestCorner.longitude, zoom);
            int x2 = long2tilex(southEastCorner.longitude, zoom);
            int y1 = lat2tiley(northWestCorner.latitude, zoom);
            int y2 = lat2tiley(southEastCorner.latitude, zoom);
            
            NSLog(@"zoom %i x: %i - %i = %i y: %i - %i = %i",zoom,x1,x2,x1-x2,y1,y2,y1-y2);
            
            
            for (NSUInteger y = y1; y <= y2; y++) {
                for (NSUInteger x = x1; x <= x2; x++) {
                    tilesDone++;
                    
                    NSString *urlString = [[[mapLayer.o_urlTile stringByReplacingOccurrencesOfString:@"{x}" withString:[NSString stringWithFormat:@"%i", x]] stringByReplacingOccurrencesOfString:@"{y}" withString:[NSString stringWithFormat:@"%i", y]] stringByReplacingOccurrencesOfString:@"{z}" withString:[NSString stringWithFormat:@"%i", zoom]];

                    
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
                    if (!data) {
                        NSLog(@"err data %@", urlString);
       //                 return ;
                    }
   
                    NSString *pathFile =  [basePath stringByAppendingString:[NSString stringWithFormat:@"/map/%@/%d-%d-%d.png", mapLayer.o_id,zoom, x, y]];
                    
                    NSError *error;
                    [data writeToFile:pathFile options:NSDataWritingAtomic error:&error];
                    if (error) {
                        NSLog(@"error %@", [error debugDescription]);
                        return ;
                    }
                }
            }
        }
        

        
        
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            // Update UI
            // Example:
            // self.myLabel.text = result;
        });
    });
    
    
    
    
    
    
    
}


#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self.treeController refresh:YES];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    if([view.annotation isKindOfClass:[KPAnnotation class]]){
        
        KPAnnotation *cluster = (KPAnnotation *)view.annotation;
        
        if(cluster.annotations.count > 1){
            [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(cluster.coordinate,
                                                                       cluster.radius * 2.5f,
                                                                       cluster.radius * 2.5f)
                           animated:YES];
        }
    } else if ([view.annotation isKindOfClass:[MKUserLocation class]]){
        [self.mapView setShowsUserLocation:NO];
    }
}


- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
    
    if([annotation isKindOfClass:[KPAnnotation class]]){
        
        KPAnnotation *a = (KPAnnotation *)annotation;
        
        if (a.annotations.count==1) {
            
            id <MKAnnotation> place = (id <MKAnnotation>) a.annotations.anyObject;
            
            static NSString *AnnotationViewPlace = @"pin";
            MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewPlace];
            
            if (!annotationView)
            {
                annotationView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewPlace];
            }
            annotationView.canShowCallout = YES;
            return annotationView;
            
        }else{
            static NSString *AnnotationViewCluster = @"cluster";
            MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewCluster];
            
            if (annotationView == nil)
            {
                annotationView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotationViewCluster];
            }
            
            annotationView.canShowCallout = YES;
            [annotationView setPinColor:MKPinAnnotationColorPurple];
            
            
            return annotationView;
        }
    }
    return nil;
}

#pragma mark - misc
- (void)reloadMap
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.treeController setAnnotations:self.fetchedResultsController.fetchedObjects];
    
    // Walk the list of overlays and annotations and create a MKMapRect that
    // bounds all of them and store it into flyTo.
    MKMapRect flyTo = MKMapRectNull;
    
    for (id <MKAnnotation> annotation in self.fetchedResultsController.fetchedObjects) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(flyTo)) {
            flyTo = pointRect;
        } else {
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }
    }
    
    // Position the map so that all overlays and annotations are visible on screen.
    self.mapView.visibleMapRect = flyTo;
}


#pragma mark - KPTreeControllerDelegate

- (void)treeController:(KPTreeController *)tree configureAnnotationForDisplay:(KPAnnotation *)annotation {
    if (annotation.annotations.count==1 ) {
        
        id <MKAnnotation> place = (id <MKAnnotation>) annotation.annotations.anyObject;
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[place coordinate].latitude longitude:[place coordinate].longitude];
        
        [annotation setTitle:[place title]];
        
        CLLocationDistance distance = [self.mapView.userLocation.location distanceFromLocation:location];
        NSString *subtitle;
        if (distance >10000) {
            subtitle = [NSString stringWithFormat:@"%.0f km vzdálené",distance/1000];
        }else{
            subtitle = [NSString stringWithFormat:@"%.0f m vzdálené",distance];
        }
        [annotation setSubtitle:subtitle];
        
    }else{
        annotation.title = [NSString stringWithFormat:@"%lu bodů zájmu", (unsigned long)annotation.annotations.count];
        annotation.subtitle = [NSString stringWithFormat:@"%.0f metry vzdálené od sebe", annotation.radius];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self reloadMap];
}


#pragma mark - searchbar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSMutableArray *predicates = @[].mutableCopy;
    [predicates addObject:[NSPredicate predicateWithFormat:@"layer.o_isActive = YES"]];
    
    if ([searchBar.text length]) {
        [predicates addObject: [NSPredicate predicateWithFormat:@"o_title BEGINSWITH[cd] %@ AND layer.o_isActive = YES", searchBar.text]];
    }
    [self.fetchedResultsController.fetchRequest setPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates]];
    
    NSError *error = nil;
    [self.fetchedResultsController performFetch:&error];
    
    if (error) {
        // Handle error
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [self.tableViewSearch reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [self.tableViewSearch reloadData];
    [self.tableViewSearch setHidden:NO];
    [self.tableViewSearch setAlpha:0.7];
    [self.navigationItem.rightBarButtonItem setTitle:@"Cancel"];
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self searchBarDismiss];
}

- (void)searchBarDismiss{
    [self.searchBar resignFirstResponder];
    [self.tableViewSearch setHidden:YES];
    [self.navigationItem setLeftBarButtonItem:self.barButtonLeft animated:YES];
    [self.navigationItem.rightBarButtonItem setTitle:@"Maps"];
    
    if (!self.tableViewSearch.indexPathForSelectedRow) {
        [self reloadMap];
    }
}

#pragma mark - table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[self.fetchedResultsController.sections objectAtIndex:section] numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Feature *place = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [cell.textLabel setText:place.o_title];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    Feature * place = [_fetchedResultsController objectAtIndexPath:indexPath];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance([place coordinate], 1500, 1500);
    [self.mapView setRegion:viewRegion animated:YES];
    
    [self searchBarDismiss];
    
}
/*
 - (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
 {
 Place * place = [_fetchedResultsController objectAtIndexPath:indexPath];
 [self selectItemDetail:place];
 }
 */



@end
