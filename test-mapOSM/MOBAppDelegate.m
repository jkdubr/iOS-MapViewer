//
//  MOBAppDelegate.m
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 03/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "MOBAppDelegate.h"

#import "KMLParser.h"
#import "FeaturesLayer.h"
#import "Feature.h"

#import <Crashlytics/Crashlytics.h>

@implementation MOBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"69863faf3346ba912dbfd7b3287d102f291d6060"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/map"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:NULL]; //Create folder
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (url) {
        FeaturesLayer *featuresLayer = [FeaturesLayer layerWithId:url.absoluteString];
        [featuresLayer setO_title:[url lastPathComponent]];
        [featuresLayer setO_source:@"KML file"];
        [featuresLayer setO_isActive:YES];
        
        
        KMLParser *kmlParser = [[KMLParser alloc] initWithURL:url];
        [kmlParser parseKML];
        
        
        for (id <MKAnnotation> place in [kmlParser points]) {
            Feature *feature = [Feature feature];
            [feature setO_title:[place title]];
            [feature setO_text:[place subtitle]];
            
            [feature setO_lat:[place coordinate].latitude];
            [feature setO_lon:[place coordinate].longitude];
            [feature setLayer:featuresLayer];
            
        }
        [[MOBDataManager sharedManager] saveContext];
        
        //  [[NSNotificationCenter defaultCenter] postNotificationName:@"MapitoViewerDidReceiveNewURL" object:url];
    }
    
    return YES;
}

@end
