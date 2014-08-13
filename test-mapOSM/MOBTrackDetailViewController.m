//
//  MOBTrackDetailViewController.m
//  MapViewer
//
//  Created by Jakub Dubrovsky on 11/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "MOBTrackDetailViewController.h"

#import "MOBGraphLineView.h"
#import "MOBTrackPoint.h"
#import <GPXParser.h>

@interface MOBTrackDetailViewController ()

@property(nonatomic, strong) NSMutableArray *results;
@property MOBGraphLineView *viewPlot;
@end

@implementation MOBTrackDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
   
    

    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    self.results = @[].mutableCopy;
    

    
    
    NSString *str= [[NSBundle mainBundle] pathForResource:@"track" ofType:@"gpx"];
    NSData *fileData = [NSData dataWithContentsOfFile:str];
    [GPXParser parse:fileData completion:^(BOOL success, GPX *gpx) {
        // success indicates completion
        // gpx is the parsed file
        
        for (NSUInteger j=0; j<gpx.tracks.count; j++) {
            Track *track = gpx.tracks[j];
            [self.results removeAllObjects];
            CGFloat sum = 0;
            for (NSUInteger i = 0; i<track.fixes.count; i++) {
                Fix *fix = track.fixes[i];
                if (i>0) {
                    Fix *fixPrev = track.fixes[i-1];
                    CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:fix.coordinate.latitude longitude:fix.coordinate.longitude];
                    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:fixPrev.coordinate.latitude longitude:fixPrev.coordinate.longitude];
                    CLLocationDistance meters = [loc1 distanceFromLocation:loc2];
                    
                    sum = sum + meters;
                    
                    MOBTrackPoint *point = [[MOBTrackPoint alloc] initWithCoordinate:fix.coordinate atPosition:sum atElevation:fix.elevation];
                    [self.results addObject:point];
                }
            }
            
            if (j==0) {
                
                MOBGraphLineView *viewPlot = [[MOBGraphLineView alloc] initWithFrame:CGRectMake(10, 100, 300, 300)];
                [viewPlot setBackgroundColor:[UIColor redColor]];
                [viewPlot setDelegate:self];
                [self.view addSubview:viewPlot];
                return ;
            }
        }
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - graf

- (NSUInteger) mobGraphLineNumberOfItems: (MOBGraphLineView *) graph
{
    return self.results.count;
}

- (id<MOBGraphPointDelegate>) mobGraph: (MOBGraphLineView *) graph pointAtPosition:(NSUInteger) position
{
    return self.results[position];
}
- (void) mobGraph: (MOBGraphLineView *) graph didSelectedPointAtPosition:(NSUInteger) position
{
    
}

- (NSUInteger) mobGraphLineNumberOfYlines: (MOBGraphLineView *) graph
{
    return 1;
}
@end
