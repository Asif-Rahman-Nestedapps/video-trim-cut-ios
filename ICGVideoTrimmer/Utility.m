//
//  Utility.m
//  ICGVideoTrimmer
//
//  Created by Akond Asif Ur Rahman on 1/19/19.
//  Copyright © 2019 ichigo. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+(NSString*)secondToTimeFormat:(CGFloat)seconds{
    NSInteger secondsInt = (NSInteger) roundf(seconds);

    NSUInteger h = secondsInt/ 3600;
    NSUInteger m = (secondsInt/ 60) % 60;
    NSUInteger s = secondsInt % 60;
    
    NSString *formattedTime = [NSString stringWithFormat:@"%lu:%02lu:%02lu", (unsigned long)h, (unsigned long)m, (unsigned long)s];
    return formattedTime;
}


+ (void)showProgressHUD:(UIView*)view{
    [MBProgressHUD showHUDAddedTo:view animated:true];
}
+ (void)hidProgressHUD:(UIView*)view{
    [MBProgressHUD hideHUDForView:view  animated:true];
}


@end
