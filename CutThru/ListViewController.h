//
//  ListViewController.h
//  CutThru
//
//  Created by jdanzig on 3/5/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuildingManager.h"

@import MapKit;

@interface ListViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, BuildingDelegate>
- (IBAction)mapButtonPressed:(id)sender;

@property (strong, nonatomic) CLLocation *currentLocation;
@property NSArray *buildingsArray;

@end
