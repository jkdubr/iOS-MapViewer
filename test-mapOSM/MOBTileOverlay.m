//
//  MOBTileOverlay.m
//  test-mapOSM
//
//  Created by Jakub Dubrovsky on 08/05/14.
//  Copyright (c) 2014 Mobera. All rights reserved.
//

#import "MOBTileOverlay.h"

@interface MOBTileOverlay  ()

@property NSCache *cache;
@property NSOperationQueue *operationQueue;

@end

@implementation MOBTileOverlay

- (id)initWithURLTemplate:(NSString *)URLTemplate amdWithId:(NSString *) xid
{
    if (self = [self initWithURLTemplate:URLTemplate]) {
        self.o_id = xid;
        if (!self.o_id) {
            self.o_id = @"default";
        }
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/map/%@", self.o_id]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
            [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:NULL]; //Create folder
        
    }
    return self;
}

- (NSString *) cacheMapPath:(MKTileOverlayPath)path
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [basePath stringByAppendingString:[NSString stringWithFormat:@"/map/%@/%d-%d-%d.png",self.o_id, path.z, path.x, path.y]];
}

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData *data, NSError *error))result
{
    if (!result) {
        return;
    }
    
    
    NSString *cachePath = [self cacheMapPath:path];
    
    NSData *cachedData = [NSData dataWithContentsOfFile:cachePath];
    if (cachedData) {
        result(cachedData, nil);
    }
    

        NSURLRequest *request = [NSURLRequest requestWithURL:[self URLForTilePath:path]];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            NSString *pathFile = [self cacheMapPath:path];
            NSError *error;
            [data writeToFile:pathFile options:NSDataWritingAtomic error:&error];
//            if (error) {
//                NSLog(@"error %@", [error debugDescription]);
//            }            
            result(data, connectionError);
        }];
}

@end
