//
//  TweetsViewController.m
//  iosapp
//
//  Created by chenhaoxiang on 14-10-14.
//  Copyright (c) 2014年 oschina. All rights reserved.
//

#import "TweetsViewController.h"
#import "TweetDetailsViewController.h"
#import "TweetDetailsWithBottomBarViewController.h"
#import "UserDetailsViewController.h"
#import "ImageViewController.h"
#import "OSCTweet.h"
#import "TweetCell.h"
#import "Utils.h"
#import "Config.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface TweetsViewController ()

@property (nonatomic, assign) int64_t uid;

@end

@implementation TweetsViewController

/*! Primary view has been loaded for this view controller
 
 */

- (instancetype)initWithTweetsType:(TweetsType)type {
    self = [super init];
    if (self) {
        switch (type) {
            case TweetsTypeAllTweets:
                self.uid = 0;
                break;
                
            case TweetsTypeHotestTweets:
                self.uid = -1;
                break;
                
            case TweetsTypeOwnTweets:
                self.uid = [Config getOwnID];
                if (self.uid == 0) {
                    //显示其他
                }
            default:
                break;
        }
        
        [self setBlockAndClass];
    }
    
    return self;
}

- (instancetype)initWithUserID:(int64_t)userID
{
    self = [super init];
    if (!self) {return nil;}
    
    self.uid = userID;
    [self setBlockAndClass];
    
    return self;
}

- (instancetype)initWIthSoftwareID:(int64_t)softwareID {
    self = [super init];
    if (self) {
        self.generateURL = ^NSString *(NSUInteger page) {
            return [NSString stringWithFormat:@"%@%@?project=%lld&pageIndex=%lu&%@", OSCAPI_PREFIX, OSCAPI_SOFTWARE_TWEET_LIST, softwareID, (unsigned long)page, OSCAPI_SUFFIX];
        };
        
        self.objClass = [OSCTweet class];
    }
    
    return self;
}

- (void)setBlockAndClass
{
    __weak TweetsViewController *weakSelf = self;
    self.tableWillReload = ^(NSUInteger responseObjectsCount) {
        if (weakSelf.uid == -1) {[weakSelf.lastCell statusFinished];}
        else {responseObjectsCount < 20? [weakSelf.lastCell statusFinished]: [weakSelf.lastCell statusMore];}
    };
    
    self.generateURL = ^NSString *(NSUInteger page) {
        return [NSString stringWithFormat:@"%@%@?uid=%lld&pageIndex=%lu&%@", OSCAPI_PREFIX, OSCAPI_TWEETS_LIST, weakSelf.uid, (unsigned long)page, OSCAPI_SUFFIX];
    };
    
    self.objClass = [OSCTweet class];
}

- (NSArray *)parseXML:(ONOXMLDocument *)xml {
    return [[xml.rootElement firstChildWithTag:@"tweets"] childrenWithTag:@"tweet"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // tableView设置
    [self.tableView registerClass:[TweetCell class] forCellReuseIdentifier:kTweeWithoutImagetCellID];
    [self.tableView registerClass:[TweetCell class] forCellReuseIdentifier:kTweetWithImageCellID];
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    [menuController setMenuItems:@[[[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(copyText:)],[[UIMenuItem alloc] initWithTitle:@"删除" action:@selector(deleteTweet:)]]];
    [menuController setMenuVisible:YES animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// 图片的高度计算方法参考 http://blog.cocoabit.com/blog/2013/10/31/guan-yu-uitableview-zhong-cell-zi-gua-ying-gao-du-de-wen-ti/
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger row = indexPath.row;
    if (row < self.objects.count) {
        OSCTweet *tweet = self.objects[row];
        NSString *cellID = tweet.hasAnImage? kTweetWithImageCellID : kTweeWithoutImagetCellID;
        TweetCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
        
        [self setBlockForTweetCell:cell];
        [cell setContentWithTweet:tweet];
        if (tweet.hasAnImage) {
            UIImage *image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:tweet.smallImgURL.absoluteString];
            // 有图就加载，无图则下载并reload tableview
            if (!image) {
                [self downloadImageThenReload:tweet.smallImgURL];
            } else {
                [cell.thumbnail setImage:image];
            }
        }
        cell.portrait.tag = row;
        cell.authorLabel.tag = row;
        cell.thumbnail.tag = row;
        [cell.portrait addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushDetailsView:)]];
        [cell.authorLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pushDetailsView:)]];
        [cell.thumbnail addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadLargeImage:)]];
        return cell;
    } else {
        return self.lastCell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.objects.count) {
        OSCTweet *tweet = self.objects[indexPath.row];
        [self.label setAttributedText:[Utils emojiStringFromRawString:tweet.body]];
        
        CGSize size = [self.label sizeThatFits:CGSizeMake(tableView.frame.size.width - 57, MAXFLOAT)];
        CGFloat heigth = size.height + 65;
        if (tweet.hasAnImage) {
            UIImage *image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:tweet.smallImgURL.absoluteString];
            if (!image) {
                image = [UIImage imageNamed:@"portrait_loading"];
            }
            heigth += image.size.height;
        }
        return heigth;
    } else {
        return 60;
    }
}

#pragma mark -- UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger row = indexPath.row;
    
    if (row < self.objects.count) {
        OSCTweet *tweet = self.objects[row];
        
        TweetDetailsWithBottomBarViewController *tweetDetailsBVC = [[TweetDetailsWithBottomBarViewController alloc] initWithTweetID:tweet.tweetID];
        [self.navigationController pushViewController:tweetDetailsBVC animated:YES];
        
    } else {
        [self fetchMore];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copyText:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    //required
}

#pragma mark - 下载图片
- (void)downloadImageThenReload:(NSURL *)imageURL
{
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                          options:SDWebImageDownloaderUseNSURLCache
                                                         progress:nil
                                                        completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                            [[SDImageCache sharedImageCache] storeImage:image forKey:imageURL.absoluteString toDisk:NO];
                                                            
                                                            // 单独刷新某一行会有闪烁，全部reload反而较为顺畅
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                [self.tableView reloadData];
                                                            });
                                                        }];
}

#pragma mark - 跳转到用户详情页

- (void)pushDetailsView:(UITapGestureRecognizer *)recognizer
{
    OSCTweet *tweet = self.objects[recognizer.view.tag];
    UserDetailsViewController *userDetailsVC = [[UserDetailsViewController alloc] initWithUserID:tweet.authorID];
    [self.navigationController pushViewController:userDetailsVC animated:YES];
}

#pragma mark - 加载大图
- (void)loadLargeImage:(UITapGestureRecognizer *)recognizer
{
    OSCTweet *tweet = self.objects[recognizer.view.tag];
    
    ImageViewController *imageVC = [[ImageViewController alloc] initWithImageURL:tweet.bigImgURL thumbnail:(UIImageView *)recognizer.view andTapLocation:[recognizer locationInView:self.view]];
    
    [self presentViewController:imageVC animated:YES completion:nil];
}

- (void)setBlockForTweetCell:(TweetCell *)cell {
    cell.canPerformAction = ^ BOOL (UITableViewCell *cell, SEL action) {
        if (action == @selector(copyText:)) {
            return YES;
        } else if (action == @selector(deleteTweet:)) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            OSCTweet *tweet = self.objects[indexPath.row];
            int64_t ownID = [Config getOwnID];
            
            return tweet.authorID == ownID;
        }
        
        return NO;
    };
    
    cell.deleteTweet = ^ (UITableViewCell *cell) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        OSCTweet *tweet = self.objects[indexPath.row];
        
        MBProgressHUD *HUD = [Utils createHUDInWindowOfView:self.view];
        HUD.labelText = @"正在删除动弹";
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
        [manager POST:[NSString stringWithFormat:@"%@%@?", OSCAPI_PREFIX, OSCAPI_TWEET_DELETE]
           parameters:@{
                        @"uid": @([Config getOwnID]),
                        @"tweetid": @(tweet.tweetID)
                        }
              success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseObject) {
                  ONOXMLElement *resultXML = [responseObject.rootElement firstChildWithTag:@"result"];
                  int errorCode = [[[resultXML firstChildWithTag: @"errorCode"] numberValue] intValue];
                  NSString *errorMessage = [[resultXML firstChildWithTag:@"errorMessage"] stringValue];
                  
                  HUD.mode = MBProgressHUDModeCustomView;
                  
                  switch (errorCode) {
                      case 1: {
                          HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                          HUD.labelText = @"动弹删除成功";
                          
                          [self.objects removeObjectAtIndex:indexPath.row];
                          [self.tableView beginUpdates];
                          [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                          [self.tableView endUpdates];
                          
                          break;
                      }
                      case 0:
                      case -2:
                      case -1: {
                          HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                          HUD.labelText = [NSString stringWithFormat:@"错误：%@", errorMessage];
                          break;
                      }
                      default: break;
                  }
                  
                  [HUD hide:YES afterDelay:2];
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  HUD.mode = MBProgressHUDModeCustomView;
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  HUD.labelText = @"网络异常，操作失败";
                  
                  [HUD hide:YES afterDelay:2];
              }];
    };
}


@end
