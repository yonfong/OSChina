//
//  NewsDetailsViewController.h
//  OSChina
//
//  Created by sky on 15/7/1.
//  Copyright (c) 2015年 bluesky. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSCNews;

@interface NewsDetailsViewController : UIViewController

- (instancetype)initWithNews:(OSCNews *)news;

@end
