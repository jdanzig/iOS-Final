//
//  ViewController.m
//  CutThru
//
//  Created by jdanzig on 3/5/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import "ViewController.h"
#import "ContainerViewController.h"
#import "Reachability.h"

@interface ViewController ()
@property (nonatomic, weak) ContainerViewController *containerViewController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _navBar.backgroundColor = [UIColor cyanColor];
    
    if (!self.checkForNetwork) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No network connection"
                                                        message:@"This would matter if we were downloading JSON files from online."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    // Recording the first time the app is used
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:@"Initial Launch"];
    if (!date) {
        NSLog(@"Launched for the first time.");
        date = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"Initial Launch"];
    }
    NSLog(@"App first used on %@",date);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if ([segue.identifier isEqualToString:@"embedContainer"]) {
        self.containerViewController = segue.destinationViewController;
    }
    
    if ([segue.identifier isEqualToString:@"infoPopoverSegue"]) {
        UINavigationController *destNav = segue.destinationViewController;
        
        // This is the important part
        UIPopoverPresentationController *popPC = destNav.popoverPresentationController;
        popPC.delegate = self;
    }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

- (IBAction)containerButtonPressed:(id)sender {
    NSLog(@"Container Button Pressed");
    
    [self.containerViewController swapViewControllers];
    if ([self.containerButton.title isEqual:@"List View"]) {
        [self.containerButton setTitle:@"Map View"];
    } else {
        [self.containerButton setTitle:@"List View"];
    }
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
