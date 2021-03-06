//
//  main.m
//  Salat
//
//  Created by Skander Jabouzi on 2015-04-06.
//  Copyright (c) 2015 Skander Jabouzi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Salat.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSMutableArray *salaTimes = [[NSMutableArray alloc] init];
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];

        int year = (int)[components year];
        int month = (int)[components month];
        int day = (int)[components day];
        int calcMethod = 2;
        int asrMethod = 0;
        int highLatitude = 0;
        float latitude = 45.5454;
        float longitude = -73.6391;
        float timezone = -4;
        
        Salat *prayers = [[Salat alloc] init];
        [prayers setCalcMethod:calcMethod];
        [prayers setAsrMethod:asrMethod];
        [prayers setDhuhrMinutes:0];
        [prayers setHighLatsMethod:highLatitude];
        
        salaTimes = [prayers getDatePrayerTimes:year:month:day:latitude:longitude:timezone];
        NSLog(@"salaTimes a %@", salaTimes);

    }
    return 0;
}
