//
//  ViewController.h
//  CutThru
//
//  Created by jdanzig on 3/5/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIPopoverPresentationControllerDelegate>

- (IBAction)containerButtonPressed:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *containerButton;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;

@end