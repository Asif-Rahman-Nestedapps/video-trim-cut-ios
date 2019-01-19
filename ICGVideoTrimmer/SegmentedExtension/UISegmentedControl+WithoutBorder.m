//
//  UISegmentedControl+WithoutBorder.m
//  ICGVideoTrimmer
//
//  Created by Akond Asif Ur Rahman on 1/12/19.
//  Copyright © 2019 ichigo. All rights reserved.
//

#import "UISegmentedControl+WithoutBorder.h"

@implementation UISegmentedControl (WithoutBorder)

-(void)removeBorder{
    self.layer.cornerRadius = 4.0;
    self.layer.masksToBounds = YES;
    [self setBackgroundImage:[self imageWithColor:self.backgroundColor] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [self setBackgroundImage:[self imageWithColor:self.tintColor] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [self setDividerImage:[self imageWithColor:self.backgroundColor] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [UIFont boldSystemFontOfSize:16], NSFontAttributeName,
                                self.tintColor, NSForegroundColorAttributeName,
                                nil];
    [self setTitleTextAttributes:attributes forState:UIControlStateNormal];
    NSDictionary *highlightedAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [UIFont boldSystemFontOfSize:16], NSFontAttributeName,
                                [UIColor whiteColor], NSForegroundColorAttributeName,
                                nil];
    [self setTitleTextAttributes:highlightedAttributes forState:UIControlStateSelected];

}


-(UIImage*)imageWithColor:(UIColor *)color{
    CGRect rect = CGRectMake(0, 0, 1.0, 1.0);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
