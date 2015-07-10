//
//  ContainerViewController.m
//  EmbeddedSwapping
//
//  Created by jdanzig on 3/5/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//  heavily pulled from https://github.com/mluton/EmbeddedSwapping/tree/master/EmbeddedSwapping
//

#import "ContainerViewController.h"
#import "MapViewController.h"
#import "ListViewController.h"
#import "ViewController.h"

#define segueFromMap @"embedMap"
#define segueFromList @"embedList"

@interface ContainerViewController ()

@property (strong, nonatomic) NSString *currentSegueIdentifier;
@property (strong, nonatomic) MapViewController *mapViewController;
@property (strong, nonatomic) ListViewController *listViewController;
@property (assign, nonatomic) BOOL transitionInProgress;

@end

@implementation ContainerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.transitionInProgress = NO;
    self.currentSegueIdentifier = segueFromMap;
    [self performSegueWithIdentifier:self.currentSegueIdentifier sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    // Instead of creating new VCs on each seque we want to hang on to existing
    // instances if we have it. Remove the second condition of the following
    // two if statements to get new VC instances instead.
    if ([segue.identifier isEqualToString:segueFromMap]) {
        self.mapViewController = segue.destinationViewController;
    }
    
    if ([segue.identifier isEqualToString:segueFromList]) {
        self.listViewController = segue.destinationViewController;
    }
    
    // If we're going to the first view controller.
    if ([segue.identifier isEqualToString:segueFromMap]) {
        // If this is not the first time we're loading this.
        if (self.childViewControllers.count > 0) {
            [self swapFromViewController:[self.childViewControllers objectAtIndex:0] toViewController:self.mapViewController];
        }
        else {
            // If this is the very first time we're loading this we need to do
            // an initial load and not a swap.
            [self addChildViewController:segue.destinationViewController];
            UIView* destView = ((UIViewController *)segue.destinationViewController).view;
            destView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            destView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
            [self.view addSubview:destView];
            [segue.destinationViewController didMoveToParentViewController:self];
        }
    }
    // By definition the second view controller will always be swapped with the
    // first one.
    else if ([segue.identifier isEqualToString:segueFromList]) {
        [self swapFromViewController:[self.childViewControllers objectAtIndex:0] toViewController:self.listViewController];
        NSLog(@"Seguing to List View with location %@",[self.mapViewController currentLocation]);
        //[self.listViewController setCurrentLoc:[self.mapViewController currentLocation]];
    }

}

- (void)swapFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    toViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];
    
    [self transitionFromViewController:fromViewController toViewController:toViewController duration:0.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:nil completion:^(BOOL finished) {
        [fromViewController removeFromParentViewController];
        [toViewController didMoveToParentViewController:self];
        self.transitionInProgress = NO;
    }];
}

- (void)swapViewControllers
{
    NSLog(@"swapViewControllers");
    
    if (self.transitionInProgress) {
        return;
    }
    
    self.transitionInProgress = YES;
    self.currentSegueIdentifier = ([self.currentSegueIdentifier isEqualToString:segueFromMap]) ? segueFromList : segueFromMap;
    
    if (([self.currentSegueIdentifier isEqualToString:segueFromMap]) && self.mapViewController) {
        [self swapFromViewController:self.listViewController toViewController:self.mapViewController];
        NSLog(@"Seguing to Map View");
        return;
    }
    
    if (([self.currentSegueIdentifier isEqualToString:segueFromList]) && self.listViewController) {
        [self swapFromViewController:self.mapViewController toViewController:self.listViewController];
        NSLog(@"Seguing to List View with location %@",[self.mapViewController currentLocation]);
        //[self.listViewController setCurrentLoc:[self.mapViewController currentLocation]];
        return;
    }
    
    [self performSegueWithIdentifier:self.currentSegueIdentifier sender:nil];
}



@end
