//
//  InfoViewController.m
//  CutThru
//
//  Created by jdanzig on 3/13/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import "InfoViewController.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"infoback.png"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"infoback.png"]];
    
    _infoTitle.textColor = [UIColor whiteColor];
    _infoTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    
    [_infoText sizeToFit];
    _infoText.textColor = [UIColor whiteColor];
    _infoText.text = @"Dear User,\n\nThank you for purchasing our app. CutThru is a personal pedestrian assistant that will help you avoid bad weather or inconvenient walking routes by finding shortcuts through publicly accessible buildings. With an expansive database spanning numerous cities, CutThru will get you to your destination with speed and comfort. Happy walking!\n\nJonathan Danzig";
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
