//
//  Salat.m
//  Salat
//
//  Created by Skander Jabouzi on 2015-01-21.
//  Copyright (c) 2015 Skander Jabouzi. All rights reserved.
//

#import "Salat.h"

@implementation Salat

- (id)init
{
    self = [super init];
    if (self)
    {

        PI = 4.0*atan(1.0);
        // Calculation Methods
        Jafari     = 0;    // Ithna Ashari
        Karachi    = 1;    // University of Islamic Sciences, Karachi
        ISNA       = 2;    // Islamic Society of North America (ISNA)
        MWL        = 3;    // Muslim World League (MWL)
        Makkah     = 4;    // Umm al-Qura, Makkah
        Egypt      = 5;    // Egyptian General Authority of Survey
        Tehran     = 6;    // Institute of Geophysics, University of Tehran
        Custom     = 7;    // Custom Setting
        
        // Juristic Methods
        Shafii     = 0;    // Shafii (standard)
        Hanafi     = 1;    // Hanafi
        
        // Adjusting Methods for Higher Latitudes
        None       = 0;    // No adjustment
        MidNight   = 1;    // middle of night
        OneSeventh = 2;    // 1/7th of night
        AngleBased = 3;    // angle/60th of night
        
        
        // Time Formats
        Time24     = 0;    // 24-hour format
        Time12     = 1;    // 12-hour format
        Time12NS   = 2;    // 12-hour format with no suffix
        Float      = 3;    // floating point number
        
        // Time Names
        //timeNames = {'Fajr','Sunrise','Dhuhr','Asr','Sunset','Maghrib','Isha'};
        
        InvalidTime = @"-----";     // The string used for invalid times
        
        
        //---------------------- Global Variables --------------------
        
        
        calcMethod   = 0;        // caculation method
        asrJuristic  = 0.0;        // Juristic method for Asr
        dhuhrMinutes = 0.0;        // minutes after mid-day for Dhuhr
        adjustHighLats = 0;    // adjusting method for higher latitudes
        
        timeFormat   = 0;        // time format
        
        
        //--------------------- Technical Settings --------------------
        
        
        numIterations = 1;        // number of iterations needed to compute times
        
        methodParams[0][0] = 16.0;
        methodParams[0][1] = 0.0;
        methodParams[0][2] = 4.0;
        methodParams[0][3] = 0.0;
        methodParams[0][4] = 14.0;
        
        methodParams[1][0] = 18.0;
        methodParams[1][1] = 1.0;
        methodParams[1][2] = 0.0;
        methodParams[1][3] = 0.0;
        methodParams[1][4] = 18.0;
        
        methodParams[2][0] = 15.0;
        methodParams[2][1] = 1.0;
        methodParams[2][2] = 0.0;
        methodParams[2][3] = 0.0;
        methodParams[2][4] = 15.0;
        
        methodParams[3][0] = 18.0;
        methodParams[3][1] = 1.0;
        methodParams[3][2] = 0.0;
        methodParams[3][3] = 0.0;
        methodParams[3][4] = 17.0;
        
        methodParams[4][0] = 19.0;
        methodParams[4][1] = 1.0;
        methodParams[4][2] = 0.0;
        methodParams[4][3] = 1.0;
        methodParams[4][4] = 90.0;
        
        methodParams[5][0] = 19.5;
        methodParams[5][1] = 1.0;
        methodParams[5][2] = 0.0;
        methodParams[5][3] = 0.0;
        methodParams[5][4] = 17.5;
        
        methodParams[6][0] = 18.0;
        methodParams[6][1] = 1.0;
        methodParams[6][2] = 0.0;
        methodParams[6][3] = 0.0;
        methodParams[6][4] = 17.0;
        
        methodParams[7][0] = 17.7;
        methodParams[7][1] = 0.0;
        methodParams[7][2] = 4.5;
        methodParams[7][3] = 0.0;
        methodParams[7][4] = 15.0;
        
        times = [[NSMutableArray alloc] initWithCapacity:7];
        prayerTimes = [[NSMutableArray alloc] initWithCapacity:7];
        
    }
    return self;
}

- (NSMutableArray *)getDatePrayerTimes:(int)year :(int)month :(int)day :(double)latitude :(double)longitude :(double)timeZone
{
    lat = latitude;
    lng = longitude;
    timezone = timeZone;
    //timeZone = effectiveTimeZone(year, month, day, timeZone);
    JDate = [self julianDate:year:month:day] - longitude / (15 * 24);
    [self computeDayTimes];

    return prayerTimes;
}

// set the calculation method
- (void) setCalcMethod:(int)methodID
{
    calcMethod = methodID;
}

// set the juristic method for Asr
- (void) setAsrMethod:(int)methodID
{
    if (methodID < 0 || methodID > 1)
        return;
    asrJuristic = methodID;
}


// set the minutes after mid-day for calculating Dhuhr
- (void) setDhuhrMinutes:(int)minutes
{
    dhuhrMinutes = minutes;
}

// set the minutes after Sunset for calculating Maghrib
- (void) setMaghribMinutes:(int)minutes
{
    //double *customParams[] = {NULL, 1, &minutes, NULL, NULL};
}

// set the minutes after Maghrib for calculating Isha
- (void) setIshaMinutes:(int)minutes
{
    //double *customParams[] = {NULL, 1, &minutes, NULL, NULL};
}

// set adjusting method for higher latitudes
- (void) setHighLatsMethod:(int)methodID
{
    adjustHighLats = methodID;
}

// set the time format
- (void) setTimeFormat:(int)_timeFormat
{
    timeFormat = _timeFormat;
}

// convert float hours to 24h format
- (NSString*) floatToTime24:(double)time
{
    if ([self isNaN:time])
        return InvalidTime;
    else{
        time = [self fixhour:(time + 0.5 / 60)];  // add 0.5 minutes to round
        double hours = floor(time);
        double minutes = floor((time - hours)* 60);
        return [NSString stringWithFormat:@"%@%@%@",[self twoDigitsFormat:hours], @":", [self twoDigitsFormat:minutes]];
    }
}

// convert float hours to 12h format
- (NSString*) floatToTime12:(double)time
{
    if ([self isNaN:time])
        return InvalidTime;
    else{
        time = [self fixhour:(time+ 0.5 / 60)];  // add 0.5 minutes to round
        int hours = ((int)time);
        int minutes = (((int)time- hours)* 60);
        
        NSString *suffix = [NSString stringWithFormat:@"%@", (hours >= 12.0 ? @" pm" : @" am")];
        hours = (hours + 12 - 1) % 12 + 1;
        return [NSString stringWithFormat:@"%d%@%@%@", hours, @":", [self twoDigitsFormat:minutes], suffix];
    }

}
                
// compute declination angle of sun and equation of time
- (double) sunPosition:(double)jd :(int)flag
{
    double D = jd - 2451545.0;
    double g = [self fixangle:(357.529 + 0.98560028 * D)];
    double q = [self fixangle:(280.459 + 0.98564736 * D)];
    double L = [self fixangle:(q + 1.915 * [self dsin:g] + 0.020 * [self dsin:(2*g)])];
    //double R = 1.00014 - 0.01671* dcos(g) - 0.00014* dcos(2*g);
    double e = 23.439 - 0.00000036* D;
    double d = [self darcsin:([self dsin:e] * [self dsin:L])];
    //double RA = darctan2(dcos(e)* dsin(L), dcos(L))/ 15;
    double RA = [self darctan2:[self dcos:e] * [self dsin:L]:[self dcos:L]] / 15;
    RA = [self fixhour:RA];
    double EqT = q/15 - RA;
    //double * result = new double[2];
    if (flag == 0) return d;
    return EqT;
}
                
// compute equation of time
- (double) equationOfTime:(double)jd
{
    return [self sunPosition:jd:1];
}
                
// compute declination angle of sun
- (double) sunDeclination:(double)jd
{
    return [self sunPosition:jd:0];
}
                
// compute mid-day (Dhuhr, Zawal) time
- (double) computeMidDay:(double)t
{
    double T = [self equationOfTime:(JDate + t)];
    double Z = [self fixhour:(12 - T)];
    return Z;
}
                
// compute time for a given angle G
- (double) computeTime:(double)G :(double)t
{
    double D = [self sunDeclination:(JDate + t)];
    double Z = [self computeMidDay:t];
    double V = 1.0/15.0* [self darccos:((-[self dsin:G] -[self dsin:D] * [self dsin:lat]) / ([self dcos:D] * [self dcos:lat]))];
    return Z + (G > 90.0 ? -V : V);
}
                
// compute the time of Asr
- (double) computeAsr:(int)step :(double)t
{
    double D = [self sunDeclination:(JDate + t)];
    double G = -[self darccot:(step + [self dtan:(abs(lat-D))])];
    return [self computeTime:G:t];
}// Shafii: step=1, Hanafi: step=2

                
//---------------------- Compute Prayer Times -----------------------
                
                
// compute prayer times at given julian date
- (void) computeTimes
{
    [self dayPortion];
    //computeTime(180.0 - methodParams[calcMethod][0], times[0]);
    double Fajr    = [self computeTime:(180.0 - methodParams[calcMethod][0]):[[times objectAtIndex:0] doubleValue]];
    double Sunrise = [self computeTime:(180.0 - 0.833):[[times objectAtIndex:1] doubleValue]];
    double Dhuhr   = [self computeMidDay:[[times objectAtIndex:2] integerValue]];
    double Asr     = [self computeAsr:(1.0 + asrJuristic):[[times objectAtIndex:0] doubleValue]];
    double Sunset  = [self computeTime:0.833:[[times objectAtIndex:4] integerValue]];
    double Maghrib = [self computeTime:methodParams[calcMethod][2]:[[times objectAtIndex:5] doubleValue]];
    double Isha    = [self computeTime:methodParams[calcMethod][4]:[[times objectAtIndex:6] doubleValue]];
    
    [times replaceObjectAtIndex:0 withObject:[NSNumber numberWithDouble:Fajr]];
    [times replaceObjectAtIndex:1 withObject:[NSNumber numberWithDouble:Sunrise]];
    [times replaceObjectAtIndex:2 withObject:[NSNumber numberWithDouble:Dhuhr]];
    [times replaceObjectAtIndex:3 withObject:[NSNumber numberWithDouble:Asr]];
    [times replaceObjectAtIndex:4 withObject:[NSNumber numberWithDouble:Sunset]];
    [times replaceObjectAtIndex:5 withObject:[NSNumber numberWithDouble:Maghrib]];
    [times replaceObjectAtIndex:6 withObject:[NSNumber numberWithDouble:Isha]];
}

// compute prayer times at given julian date
- (void) computeDayTimes
{
    [times insertObject:[NSNumber numberWithDouble:5.0] atIndex:0];
    [times insertObject:[NSNumber numberWithDouble:6.0] atIndex:1];
    [times insertObject:[NSNumber numberWithDouble:12.0] atIndex:2];
    [times insertObject:[NSNumber numberWithDouble:13.0] atIndex:3];
    [times insertObject:[NSNumber numberWithDouble:18.0] atIndex:4];
    [times insertObject:[NSNumber numberWithDouble:18.0] atIndex:5];
    [times insertObject:[NSNumber numberWithDouble:18.0] atIndex:6];
    
    for (int i=1; i<=numIterations; i++)
        [self computeTimes];
    [self adjustTimes];
    [self adjustTimesFormat];
}
 
// adjust times in a prayer time array
- (void) adjustTimes
{
    for (int i=0; i<7; i++)
    {
        double temp = [[times objectAtIndex:i] doubleValue];
        temp += timezone - lng/15.0;
        [times replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:temp]];
    }
    
    double temp = [[times objectAtIndex:2] doubleValue];
    temp += dhuhrMinutes/ 60.0;
    [times replaceObjectAtIndex:2 withObject:[NSNumber numberWithDouble:temp]];
    
    if (methodParams[calcMethod][1] == 1) // Maghrib
    {
        double temp = [[times objectAtIndex:4] doubleValue];
        temp += methodParams[calcMethod][2]/ 60.0;
        [times replaceObjectAtIndex:5 withObject:[NSNumber numberWithDouble:temp]];
    }
    
    if (methodParams[calcMethod][3] == 1) // Isha
    {
        double temp = [[times objectAtIndex:5] doubleValue];
        temp += methodParams[calcMethod][4]/ 60.0;
        [times replaceObjectAtIndex:6 withObject:[NSNumber numberWithDouble:temp]];
    }
    
    if (adjustHighLats != None) [self adjustHighLatTimes];
}
 
// convert times array to given time format
- (void) adjustTimesFormat
{
    for (int i=0; i<7; i++)
        if (timeFormat == Time12)
            [prayerTimes insertObject:[self floatToTime12:[[times objectAtIndex:i] doubleValue]] atIndex:i];
        else
            [prayerTimes insertObject:[self floatToTime24:[[times objectAtIndex:i] doubleValue]] atIndex:i];
}

// adjust Fajr, Isha and Maghrib for locations in higher latitudes
- (void) adjustHighLatTimes
{
    /*double nightTime = [self timeDiff:[[times objectAtIndex:4] integerValue]:[[times objectAtIndex:1] integerValue]]; // sunset to sunrise
    
    // Adjust Fajr
    double FajrDiff = [self nightPortion:methodParams[calcMethod][0]] * nightTime;
    if (isNaN(times[0]) || timeDiff(times[0], times[1]) > FajrDiff)
        times[0] = times[1]- FajrDiff;
    
    // Adjust Isha
    double IshaAngle = (methodParams[calcMethod][3] == 0) ? methodParams[calcMethod][4] : 18;
    double IshaDiff = nightPortion(IshaAngle)* nightTime;
    if (isNaN(times[6]) || timeDiff(times[4], times[6]) > IshaDiff)
        times[6] = times[4]+ IshaDiff;
    
    // Adjust Maghrib
    double MaghribAngle = (methodParams[calcMethod][1] == 0) ? methodParams[calcMethod][2] : 4;
    double MaghribDiff = nightPortion(MaghribAngle)* nightTime;
    if (isNaN(times[5]) || timeDiff(times[4], times[5]) > MaghribDiff)
        times[5] = times[4]+ MaghribDiff;*/
}
 
// the night portion used for adjusting times in higher latitudes
- (double) nightPortion:(double)angle
{
    double result = 0.0;
    if (adjustHighLats == AngleBased)
        result = 1.0/60.0 * angle;
    if (adjustHighLats == MidNight)
        result = 1.0/2.0;
    if (adjustHighLats == OneSeventh)
        result = 1.0/7.0;
    return result;
}
 
// convert hours to day portions
- (void) dayPortion
{
    for (int i=0; i<7; i++)
    {
        double temp = [[times objectAtIndex:i] doubleValue];
        temp /= 24;
        [times replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:temp]];
    }
}
  
//---------------------- Misc Functions -----------------------
 
 
// compute the difference between two times
- (double) timeDiff:(double)time1 : (double)time2
{
    return [self fixhour:(time2- time1)];
}
                
// add a leading 0 if necessary
- (NSString*) twoDigitsFormat:(int)num
{
    return (num <10) ? [NSString stringWithFormat:@"%@%d", @"0", num] : [NSString stringWithFormat:@"%d", num];
}
  
//bool isNaN(int);
  
  
//bool isNaN(float);
                
 
- (BOOL) isNaN:(double)var
{
     return (isnan(var) != 0);
}
 
 //---------------------- Julian Date Functions -----------------------
 
 
// calculate julian date from a calendar date
- (double) julianDate:(int)year :(int)month :(int)day
{
    if (month <= 2)
    {
        year -= 1;
        month += 12;
    }
    double A = floor(year/ 100.0);
    double B = 2.0 - A+ floor(A/ 4.0);
    
    double JD = floor(365.25* (year+ 4716))+ floor(30.6001* (month+ 1))+ day+ B- 1524.5;
    return JD;
}
  
//---------------------- Trigonometric Functions -----------------------
  
  
// degree sin
- (double) dsin:(double)d
{
    return sin([self dtr:d]);
}
    
// degree cos
- (double) dcos:(double)d
{
    return cos([self dtr:d]);
}

// degree tan
- (double) dtan:(double)d
{
    return tan([self dtr:d]);
}
  
// degree arcsin
- (double) darcsin:(double)x
{
    return [self rtd:asin(x)];
}

// degree arccos
- (double) darccos:(double)x
{
    return [self rtd:acos(x)];
}
  
// degree arctan
- (double) darctan:(double)x
{
    return [self rtd:atan(x)];
}
  
// degree arctan2
- (double) darctan2:(double)y :(double)x
{
    return [self rtd:atan2(y, x)];
}
  
// degree arccot
- (double) darccot:(double)x
{
    return [self rtd:atan(1/x)];
}

// degree to radian
- (double) dtr:(double)d
{
    return (d * PI) / 180.0;
}
 
// radian to degree
- (double) rtd:(double)r
{
    return (r * 180.0) / PI;
}
 
 // range reduce angle in degrees.
- (double) fixangle:(double)a
{
    a = a - 360.0 * (floor(a / 360.0));
    a = a < 0 ? a + 360.0 : a;
    return a;
}

// range reduce hours to 0..23
- (double) fixhour:(double)a
{
    a = a - 24.0 * (floor(a / 24.0));
    a = a < 0 ? a + 24.0 : a;
    return a;
}

@end
