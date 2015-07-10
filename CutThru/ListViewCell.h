//
//  ListViewCell.h
//  GNews RSS
//
//  Created by Jonathan Danzig on 2/13/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *buildingName;
@property (weak, nonatomic) IBOutlet UILabel *dayHours;
@property (weak, nonatomic) IBOutlet UILabel *distance;
@property (weak, nonatomic) IBOutlet UIImageView *openClosed;


@end
