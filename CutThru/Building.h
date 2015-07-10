//
//  Building.h
//  CutThru
//
//  Created by Jon on 3/5/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@import CoreLocation;

@interface Building : NSObject

- (id)initWithJSONDictionary:(NSDictionary *)jsonDictionary;

@property (strong,nonatomic) NSString *buildingName;
@property (strong,nonatomic) NSString *address;
@property (strong,nonatomic) NSDictionary *openingHour; // dictionary of NSString
@property (strong,nonatomic) NSDictionary *closingHour; // dictionary of NSString
@property (strong,nonatomic) NSMutableArray *entrances; // array of CLLocationCoordinate2D
@property (nonatomic) CGFloat distanceFromMe;

@end
