//
//  Building.m
//  CutThru
//
//  Created by Jon on 3/5/15.
//  Copyright (c) 2015 Jonathan Danzig. All rights reserved.
//

#import "Building.h"

@implementation Building

// Init the object with information from a dictionary
- (id)initWithJSONDictionary:(NSDictionary *)jsonDictionary {
    if(self = [self init]) {
        // Assign all properties with keyed values from the dictionary
        self.buildingName = [[jsonDictionary objectForKey:@"properties"] objectForKey:@"Name"];
        self.address =      [[jsonDictionary objectForKey:@"properties"] objectForKey:@"Address"];
        self.openingHour = [[[jsonDictionary objectForKey:@"properties"] objectForKey:@"Hours"] objectForKey:@"Open"];   // dictionary
        self.closingHour = [[[jsonDictionary objectForKey:@"properties"] objectForKey:@"Hours"] objectForKey:@"Closed"]; // dictionary
        self.entrances =    [[jsonDictionary objectForKey:@"geometry"] objectForKey:@"coordinates"]; // mutable array; element 0 is longitude, element 1 is latitude
    }
    
    return self;
}

@end
