//
//  MyTweetLikeListViewController.m
//  OSChina
//
//  Created by sky on 15/7/22.
//  Copyright (c) 2015年 bluesky. All rights reserved.
//

#import "MyTweetLikeListViewController.h"
#import "OSCMyTweetLikeList.h"
#import "MyTweetLikeListCell.h"

#import "UserDetailsViewController.h"
#import "TweetDetailsWithBottomBarViewController.h"

static NSString * const MyTweetLikeListCellID = @"MyTweetLikeListCell";

@interface MyTweetLikeListViewController ()

@end

@implementation MyTweetLikeListViewController
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.generateURL = ^NSString * (NSUInteger page) {
            return [NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_MY_TWEET_LIKE_LIST];
        };
        
        self.objClass = [OSCMyTweetLikeList class];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[MyTweetLikeListCell class] forCellReuseIdentifier:MyTweetLikeListCellID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSArray *)parseXML:(ONOXMLDocument *)xml {
    return [[xml.rootElement firstChildWithTag:@"likeList"] childrenWithTag:@"mytweet"];
}

#pragma mark - Table view data source

// 图片的高度计算方法参考 http://blog.cocoabit.com/blog/2013/10/31/guan-yu-uitableview-zhong-cell-zi-gua-ying-gao-du-de-wen-ti/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    if (row < self.objects.count) {
        OSCMyTweetLikeList *myTweetLikeList = self.objects[row];
        MyTweetLikeListCell *cell = [tableView dequeueReusableCellWithIdentifier:MyTweetLikeListCellID forIndexPath:indexPath];
        
        [cell setContentWithMyTweetLikeList:myTweetLikeList];
        
        cell.portrait.tag = row;
        [cell.portrait addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushUserDetailsView:)]];
        
        return cell;
    } else {
        return self.lastCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.objects.count) {
        OSCMyTweetLikeList *myTweetLikeList = self.objects[indexPath.row];
        
        self.label.font = [UIFont boldSystemFontOfSize:14];
        [self.label setText:myTweetLikeList.name];
        CGFloat height = [self.label sizeThatFits:CGSizeMake(tableView.frame.size.width - 60, MAXFLOAT)].height;
        
        [self.label setText:[NSString stringWithFormat:@"赞了我的动弹："]];
        height += [self.label sizeThatFits:CGSizeMake(tableView.frame.size.width - 60, MAXFLOAT)].height + 5;
        
        [self.label setAttributedText:myTweetLikeList.authorAndBody];
        height += [self.label sizeThatFits:CGSizeMake(tableView.frame.size.width - 60, MAXFLOAT)].height + 5;
        
        return height + 16;
    } else {
        return 60;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger row = indexPath.row;
    
    if (row < self.objects.count) {
        OSCMyTweetLikeList *myTweetLikeList = self.objects[row];
        TweetDetailsWithBottomBarViewController *tweetDetailsBVC = [[TweetDetailsWithBottomBarViewController alloc] initWithTweetID:myTweetLikeList.tweetId];
        [self.navigationController pushViewController:tweetDetailsBVC animated:YES];
    } else {
        [self fetchMore];
    }
    
}

#pragma mark - 跳转到用户详情页

- (void)pushUserDetailsView:(UITapGestureRecognizer *)recognizer
{
    OSCMyTweetLikeList *myTweetLikeList = self.objects[recognizer.view.tag];
    UserDetailsViewController *userDetailsVC = [[UserDetailsViewController alloc] initWithUserID:myTweetLikeList.userID];
    [self.navigationController pushViewController:userDetailsVC animated:YES];
}


@end