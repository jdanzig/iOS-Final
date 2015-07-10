//
//  MapViewController.h
//  CutThru
//
//  Created by jdanzig on 2/27/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MapKit;
#import "BuildingManager.h"

@interface MapViewController : UIViewController <CLLocationManagerDelegate, BuildingDelegate>

@property (strong, nonatomic) CLLocation *currentLocation;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)listButtonPressed:(id)sender;
- (IBAction)centerButtonPressed:(id)sender;
@property NSArray *buildingsArray;


@end

