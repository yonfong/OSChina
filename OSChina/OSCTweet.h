//
//  OSCTweet.h
//  iosapp
//
//  Created by chenhaoxiang on 14-10-16.
//  Copyright (c) 2014年 oschina. All rights reserved.
//

#import "OSCBaseObject.h"

@interface OSCTweet : OSCBaseObject

@property (nonatomic, assign) int64_t tweetID;
@property (nonatomic, strong) NSURL *portraitURL;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, assign) int64_t authorID;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, assign) int appclient;
@property (nonatomic, assign) int commentCount;
@property (nonatomic, copy) NSString *pubDate;
@property (nonatomic, strong) NSURL *smallImgURL;
@property (nonatomic, strong) NSURL *bigImgURL;
@property (nonatomic, copy) NSString *attach;

@end