//
//  Utils.h
//  iosapp
//
//  Created by chenhaoxiang on 14-10-16.
//  Copyright (c) 2014年 oschina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIView+Util.h"
#import "UIColor+Util.h"

@interface Utils : NSObject

+ (NSString *)getAppclient:(int)clientType;
+ (NSString *)intervalSinceNow:(NSString *)dateStr;

@end