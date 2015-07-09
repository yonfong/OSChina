//
//  EmojiPanelView.h
//  OSChina
//
//  Created by sky on 15/7/2.
//  Copyright (c) 2015年 bluesky. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EmojiPanelVC : UIViewController

@property (nonatomic, assign, readonly) int pageIndex;

@property (nonatomic,copy)void (^didSelectEmoji)(NSTextAttachment *textAttachment);

- (instancetype)initWithPageIndex:(int)pageIndex;

@end