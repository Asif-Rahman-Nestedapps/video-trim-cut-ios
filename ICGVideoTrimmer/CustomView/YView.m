//
//  YView.m
//  ICGVideoTrimmer
//
//  Created by Akond Asif Ur Rahman on 1/19/19.
//  Copyright © 2019 ichigo. All rights reserved.
//

#import "YView.h"

@implementation YView


-(id)initWithFrame:(CGRect)frame{
    if ((self = [super initWithFrame:frame])) {
        [self setUp:frame];
    }
    return self;
}


-(void)setUp:(CGRect)rect{
    CAShapeLayer *layer = [CAShapeLayer layer];
    // The Bezier path that we made needs to be converted to
    // a CGPath before it can be used on a layer.
    layer.path = [self createBeizierPath:rect].CGPath;
    // apply other properties related to the path
    layer.strokeColor = [UIColor whiteColor].CGColor;
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.lineWidth = 1.0;
    [self.layer addSublayer:layer];
    
    // add the new layer to our custom view
    
}

-(UIBezierPath*)createBeizierPath:(CGRect)rect{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))];
    [path addLineToPoint:CGPointMake(CGRectGetMidX(rect),rect.origin.y+10 )];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(rect),rect.origin.y )];
    [path moveToPoint:CGPointMake(CGRectGetMidX(rect),rect.origin.y+10 )];
    [path addLineToPoint:CGPointMake(CGRectGetMidX(rect),CGRectGetMaxY(rect) )];
    return path;
}
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
}

@end
