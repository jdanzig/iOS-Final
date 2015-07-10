//
//  ListViewController.m
//  CutThru
//
//  Created by jdanzig on 3/5/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import "ListViewController.h"
#import "ListViewCell.h"
#import "Building.h"
#import "BuildingManager.h"
#import "Reachability.h"
@import CoreLocation;

#define MINUTES_IN_DAY 1440
#define METERS_PER_MILE 1609.344
#define METERS_PER_KM 1000
#define METERS_PER_FOOT 0.3048

@interface ListViewController ()
@property (strong,nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) BuildingManager* buildingManager;
@property UIRefreshControl *refreshControl;
@end

@implementation ListViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.buildingManager = [[BuildingManager alloc] init];
    self.buildingManager.delegate = self;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    NSLog(@"currentLocation for ListView: %@",_currentLocation);
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                            action:@selector(refreshTable)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    if (!self.checkForNetwork) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection"
                                                        message:@"Unable to load table cells."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        self.buildingsArray = [[NSMutableArray alloc] init];
        [self.buildingManager getJsonData];
        [self.tableView reloadData];
        if(self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
    }
}

// self-sizing from http://useyourloaf.com/blog/2014/08/07/self-sizing-table-view-cells.html
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
    
    [self.tableView reloadData];
    NSLog(@"Reloading Data");
}

- (void) refreshTable {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    if (self.checkForNetwork) {
             [self.tableView reloadData];
             
             if(self.refreshControl.refreshing) {
                 [self.refreshControl endRefreshing];
             }

    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection"
                                                        message:@"No network connection."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        if(self.refreshControl.refreshing) {
            [self.refreshControl endRefreshing];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [self.buildingsArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    tableView.backgroundColor = [UIColor colorWithRed:180/255.0f green:255/255.0f blue:180/255.0f alpha:1.0f];
    ListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"listCell" forIndexPath:indexPath];
    
    cell.buildingName.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.buildingName.adjustsFontSizeToFitWidth = YES;
    cell.dayHours.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    
    Building *building = [self.buildingsArray objectAtIndex: indexPath.row];

    // Showing the building name
    cell.buildingName.text = building.buildingName;
    // Showing the hours
    cell.dayHours.text = [self makeHourLabel:[building.openingHour objectForKey:[self dayOfWeek]] :[building.closingHour objectForKey:[self dayOfWeek]]];
    
    // Assign door image and background color
    if ([self isOpen:[building.openingHour objectForKey:[self dayOfWeek]] :[building.closingHour objectForKey:[self dayOfWeek]]]) {
        NSLog(@"Door open, green background.");
        [cell.openClosed setImage:[UIImage imageNamed:@"door_open.png"]];
        cell.backgroundColor = [UIColor colorWithRed:130/255.0f green:255/255.0f blue:130/255.0f alpha:1.0f]; // light green
    } else {
        NSLog(@"Door closed, red background.");
        [cell.openClosed setImage:[UIImage imageNamed:@"door-closed-25.png"]];
        cell.backgroundColor = [UIColor colorWithRed:255/255.0f green:130/255.0f blue:130/255.0f alpha:1.0f]; // light red
    }
    
    ////// Assign distance from current location to the closest point on each building.
    // If location isn't available, pretend to be on Michigan Ave.
    int count = 0;
    int currentHigh = 0;
    CLLocationDistance buildingDist = INFINITY;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        NSLog(@"Authorization denied, loading default Michigan Ave. location");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Map Data Unavailable" message:@"Location Unauthorized. Pretend you're at the Gleacher Center!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
        CLLocation *workingLocation = [[CLLocation alloc] initWithLatitude:41.894754 longitude:-87.624224]; // Michigan Ave
        NSLog(@"Current location: %f,%f",_currentLocation.coordinate.longitude, _currentLocation.coordinate.latitude);
        
        // Finding the closest entrance of each building to current location.
        NSLog(@"Finding the closest entrance of each building to current location.");
        for (NSArray *entrance in building.entrances) { // This finds the
            CLLocation *buildingLoc = [[CLLocation alloc] initWithLatitude:[[entrance objectAtIndex:1] floatValue] longitude:[[entrance objectAtIndex:0] floatValue]];
            if ([workingLocation distanceFromLocation:buildingLoc] < buildingDist) {
                buildingDist = [workingLocation distanceFromLocation:buildingLoc];
                currentHigh = count;
            }
            NSLog(@"%@ entrance #%d is %f,%f",cell.buildingName.text,count++,buildingLoc.coordinate.longitude,buildingLoc.coordinate.latitude);
            NSLog(@"Closest known entrance is entrance #%d, which is %f meters away",currentHigh,buildingDist);
        }
    } else {
        NSLog(@"Current location: %f,%f",_currentLocation.coordinate.longitude, _currentLocation.coordinate.latitude);
        
        // Finding the closest entrance of each building to current location.
        NSLog(@"Finding the closest entrance of each building to current location.");
        for (NSArray *entrance in building.entrances) {
            CLLocation *buildingLoc = [[CLLocation alloc] initWithLatitude:[[entrance objectAtIndex:1] floatValue] longitude:[[entrance objectAtIndex:0] floatValue]];
            if ([_currentLocation distanceFromLocation:buildingLoc] < buildingDist) {
                buildingDist = [_currentLocation distanceFromLocation:buildingLoc];
                currentHigh = count;
            }
            NSLog(@"%@ entrance #%d is %f,%f",cell.buildingName.text,count++,buildingLoc.coordinate.longitude,buildingLoc.coordinate.latitude);
            NSLog(@"Closest known entrance is entrance #%d, which is %f meters away",currentHigh,buildingDist);
        }
    }

    // Assign distance
    cell.distance.text = [self makeDistanceLabel:buildingDist];
    
    [cell layoutIfNeeded];
    return cell;
 }

 #pragma mark - Cell Helper Functions

// Make the label for hours
- (NSString*)makeHourLabel:(NSString *)open :(NSString *)closed {
    // Showing the hours
    if ([open isEqual:@"12:00 AM"] && [closed isEqual:@"11:59 PM"]) {
        return [NSString stringWithFormat:@"Open 24 hours"];
    } else if ([open isEqual:@"Closed"]) {
        return [NSString stringWithFormat:@"Closed on %@",[self dayOfWeek]];
    } else if ([closed isEqual:@"11:59 PM"]) {
        return [NSString stringWithFormat:@"%@ - 12:00 AM", open];
    } else {
        return [NSString stringWithFormat:@"%@ - %@", open, closed];
    }
}

// Given two strings, is the place open?
- (BOOL)isOpen:(NSString *)open :(NSString *)closed {
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


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return NO;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

// In a future release, this button will be renamed "Map View" and will be used to switch to list view.
- (IBAction)mapButtonPressed:(id)sender {
    NSLog(@"Map Button Pressed");
}

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
    _currentLocation = newLocation;
}

- (void)buildingsParsed:(NSArray *)buildings {
    self.buildingsArray = buildings;
    [self.tableView reloadData];
}

// Copied from http://pinkstone.co.uk/how-to-check-for-network-connectivity-in-ios/
- (BOOL)checkForNetwork
{
    // check if we've got network connectivity
    Reachability *myNetwork = [Reachability reachabilityWithHostname:@"google.com"];
    NetworkStatus myStatus = [myNetwork currentReachabilityStatus];
    
    switch (myStatus) {
        case NotReachable:
            NSLog(@"There's no internet connection at all. Display error message now.");
            return FALSE;
            break;
            
        case ReachableViaWWAN:
            NSLog(@"We have a 3G connection");
            return TRUE;
            break;
            
        case ReachableViaWiFi:
            NSLog(@"We have WiFi.");
            return TRUE;
            break;
            
        default:
            break;
    }
}

@end
