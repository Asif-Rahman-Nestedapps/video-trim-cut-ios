//
//  Utility.h
//  ICGVideoTrimmer
//
//  Created by Akond Asif Ur Rahman on 1/19/19.
//  Copyright © 2019 ichigo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MBProgressHUD.h>
NS_ASSUME_NONNULL_BEGIN

@interface Utility : NSObject

+ (NSString*)secondToTimeFormat:(CGFloat)seconds;
+ (void)showProgressHUD:(UIView*)view;
+ (void)hidProgressHUD:(UIView*)view;

@end

NS_ASSUME_NONNULL_END
