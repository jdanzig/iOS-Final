//
//  MapViewController.m
//  CutThru
//
//  Created by jdanzig on 2/27/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import "MapViewController.h"
#import "ContainerViewController.h"
#import "Building.h"
#import "BuildingManager.h"
@import CoreLocation;

#define MINUTES_IN_DAY 1440
#define METERS_PER_MILE 1609.344
#define METERS_PER_KM 1000
#define METERS_PER_FOOT 0.3048

@interface MapViewController ()
@property (strong,nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) BuildingManager* buildingManager;

@end

#define METERS_PER_MILE 1609.344

@implementation MapViewController
@synthesize mapView;

// Working to implement http://stackoverflow.com/questions/22823772/draw-geojson-in-apple-maps-as-overlay

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.buildingManager = [[BuildingManager alloc] init];
    self.buildingManager.delegate = self;
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create a location manager and ask for permission once
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        NSLog(@"Requesting location info");
        // http://matthewfecher.com/app-developement/getting-gps-location-using-core-location-in-ios-8-vs-ios-7/
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        NSLog(@"Authorization denied, loading default Michigan Ave. location");
        // http://www.raywenderlich.com/21365/introduction-to-mapkit-in-ios-6-tutorial
        CLLocationCoordinate2D zoomLocation;
        zoomLocation.latitude = 41.894754; // Michigan Ave, Chicago
        zoomLocation.longitude= -87.624224;
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
        [mapView setRegion:viewRegion animated:YES];
    } else {
        NSLog(@"Authorization accepted, loading user location");
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = kCLLocationAccuracyKilometer;
        
        [self.locationManager startUpdatingLocation];
        self.mapView.showsUserLocation = YES;
        [self.mapView userLocation];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.buildingsArray = [[NSMutableArray alloc] init];
    [self.buildingManager getJsonData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    
    int buildingIndex = 0;
    while (buildingIndex < self.buildingsArray.count) {
        Building *building = [self.buildingsArray objectAtIndex:buildingIndex];
        
        NSLog(@"Dropping pins, but only if they're open.");
        for (NSArray *entrance in building.entrances) {
            if ([self isOpen:[building.openingHour objectForKey:[self dayOfWeek]] :[building.closingHour objectForKey:[self dayOfWeek]]]) {
                MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
                CLLocation *buildingLoc = [[CLLocation alloc] initWithLatitude:[[entrance objectAtIndex:1] floatValue] longitude:[[entrance objectAtIndex:0] floatValue]];
                CLLocationCoordinate2D myCoordinate;
                myCoordinate.latitude =  [[entrance objectAtIndex:1] floatValue];
                myCoordinate.longitude = [[entrance objectAtIndex:0] floatValue];
                CLLocationDistance buildingDist = [_currentLocation distanceFromLocation:buildingLoc];
                
                annotation.coordinate = myCoordinate;
                annotation.title = building.buildingName;
                annotation.subtitle = [NSString stringWithFormat:@"%@ - %@",building.address,[self makeDistanceLabel:buildingDist]];
                [self.mapView addAnnotation:annotation];
                NSLog(@"Dropped pin at %@, %@, <%f,%f>",annotation.title,annotation.subtitle,myCoordinate.longitude,myCoordinate.latitude);
            }
        }
        
        buildingIndex++;
    }
    
}

// Given two strings, is the place open?
- (BOOL)isOpen:(NSString *)open
              :(NSString *)closed {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hh-mm a"];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // Extract opening time from the NSDate structure
    NSDate *openDate = [dateFormatter dateFromString:open];
    NSLog(@"Open Date: %@",openDate);
    if (openDate == nil) return NO;
    NSDateComponents *openComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:openDate];
    NSInteger openTime = [openComponents hour]*60 + [openComponents minute];
    
    // Extract closing time from the NSDate structure
    NSDate *closeDate = [dateFormatter dateFromString:closed];
    NSLog(@"Close Date: %@",closeDate);
    if (closeDate == nil) return NO;
    NSDateComponents *closedComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:closeDate];
    NSInteger closedTime = [closedComponents hour]*60 + [closedComponents minute];
    if (openTime > closedTime) {
        closedTime += MINUTES_IN_DAY;
    }
    
    // Extract current time from the NSDate structure
    NSDate *currentDate = [NSDate date];
    NSLog(@"Current Date: %@",currentDate);
    NSDateComponents *currentComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:currentDate];
    NSInteger currentTime = [currentComponents hour]*60 + [currentComponents minute];
    
    return (openTime <= currentTime && currentTime <= closedTime);
}


// Return day of the week to determine today's hours
- (NSString *)dayOfWeek {
    // http://stackoverflow.com/questions/11377678/day-of-the-week-in-objective-c to get today's day of the week
    NSDate *today = [NSDate date];
    NSDateFormatter *myFormatter = [[NSDateFormatter alloc] init];
    [myFormatter setDateFormat:@"EEEE"]; // day, like "Saturday"
    [myFormatter setDateFormat:@"c"]; // day number, like 7 for saturday
    NSString *dayOfWeek = [myFormatter stringFromDate:today];
    //NSLog(@"Today it is: %@", dayOfWeek);
    int daynum = [dayOfWeek intValue];
    switch (daynum)
    {
        case 1:
            return @"Sunday";
            break;
        case 2:
            return @"Monday";
            break;
        case 3:
            return @"Tuesday";
            break;
        case 4:
            return @"Wednesday";
            break;
        case 5:
            return @"Thursday";
            break;
        case 6:
            return @"Friday";
            break;
        default: // case 7
            return @"Saturday";
            break;
    }
    
}

// Make the label for distance
- (NSString*)makeDistanceLabel:(CLLocationDistance)distance {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *metricSystem = [defaults objectForKey:@"metric_system"];
    if([metricSystem isEqual: @1]){
        if(distance < 1000/2) {
            NSLog(@"Showing distance in meters");
            return [NSString stringWithFormat:@"%.0f m", distance];
        } else {
            NSLog(@"Showing distance in kilometers");
            return [NSString stringWithFormat:@"%.1f km", distance/METERS_PER_KM];
        }
    } else {
        if(distance < METERS_PER_MILE/4) {
            NSLog(@"Showing distance in feet");
            return [NSString stringWithFormat:@"%.0f ft",distance/METERS_PER_FOOT];
        } else {
            NSLog(@"Showing distance in miles");
            return [NSString stringWithFormat:@"%.1f mi", distance/METERS_PER_MILE];
        }
    }
}

// Typical locationManager stuff
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        
        // Configure location manager
        [self.locationManager setDistanceFilter:500]; // meters
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [self.locationManager setHeadingFilter:kCLDistanceFilterNone];
        self.locationManager.activityType = CLActivityTypeFitness;
        
        // Start updating
        [self.locationManager startUpdatingLocation];
        
    } else if (status == kCLAuthorizationStatusDenied) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location services not authorized"
                                                        message:@"This app needs you to authorize location services to work."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        NSLog(@"Wrong location status");
    }
}

#pragma mark - CLLocationManagerDelegate

// From http://www.appcoda.com/how-to-get-current-location-iphone-user/
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
    _currentLocation = newLocation;
    
    /*if (_currentLocation != nil) {
     NSLog(@"Longitude: %@",[NSString stringWithFormat:@"%.8f", _currentLocation.coordinate.latitude]);
     NSLog(@"Latitude: %@",[NSString stringWithFormat:@"%.8f", _currentLocation.coordinate.longitude]);
     }*/
}

// In a future release, this button will be renamed "List View" and will be used to switch to list view.
- (IBAction)listButtonPressed:(id)sender {
    NSLog(@"Inoperable List Button Pressed");
}

// Button to zoom and center on current location, also making map upright
- (IBAction)centerButtonPressed:(id)sender {
    NSLog(@"CenterButtonPressed");
    [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.mapView.userLocation.coordinate, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    [mapView setRegion:viewRegion animated:YES];
}

// Calling buildings for Map
- (void)buildingsParsed:(NSArray *)buildings {
    self.buildingsArray = buildings;
    // [self.mapView reloadInputViews];
}

@end