//
//  BuildingManager.m
//  CutThru
//
//  Created by Julie Soliman on 3/18/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import "BuildingManager.h"
#import "Building.h"

@implementation BuildingManager

- (instancetype)init {
    self = [super init];
    if (self) {
        self.buildingsArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)loadJSONData{
    
    if(self.jsonDict){
        NSLog(@"Dictionary is not nil");
        //NSLog(@"%@",[[self.jsonDict objectForKey:@"features"] allKeys] );
        NSLog(@"%@",[self.jsonDict allKeys] );
        
        //features is an array of dictionarys
        NSLog(@"%@", [[self.jsonDict objectForKey:@"features"] class]  );
        
        for(NSDictionary * buildingDictionary in [self.jsonDict objectForKey:@"features"] ){
            Building *building = [[Building alloc] initWithJSONDictionary:buildingDictionary];
            [self.buildingsArray addObject: building];
        }
        
        
    }else{
        NSLog(@"Dictionary is nil");
    }
    
    [self.delegate buildingsParsed:self.buildingsArray];
}

- (void)getJsonData {
    // Retrieve local JSON file called Buildings.geojson
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Buildings" ofType:@"geojson"];
        
        [[NSFileManager defaultManager] fileExistsAtPath:@"Buildings.geojson"];
        NSLog(@"\"Downloading\" local JSON data");
        
        NSData *JSONData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil];
        self.jsonDict = [NSJSONSerialization JSONObjectWithData:JSONData options:NSJSONReadingMutableContainers error:nil];
        [self performSelectorOnMainThread:@selector(loadJSONData) withObject:nil waitUntilDone:YES];
        
    });
}

@end
