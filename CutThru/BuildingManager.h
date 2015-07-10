//
//  BuildingManager.h
//  CutThru
//
//  Created by Julie Soliman on 3/18/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BuildingDelegate
- (void)buildingsParsed:(NSArray *)buildings;
@end

@interface BuildingManager : NSObject

- (void)getJsonData;
@property NSDictionary *jsonDict;
@property NSMutableArray *buildingsArray;
@property (strong,nonatomic) id<BuildingDelegate> delegate;

@end
