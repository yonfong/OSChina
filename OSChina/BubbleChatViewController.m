//
//  BubbleChatViewController.m
//  OSChina
//
//  Created by sky on 15/7/14.
//  Copyright (c) 2015年 bluesky. All rights reserved.
//

#import "BubbleChatViewController.h"
#import "MessageBubbleViewController.h"
#import "Config.h"
#import "Utils.h"

#import <MBProgressHUD.h>

@interface BubbleChatViewController ()

@property (nonatomic, assign) int64_t userID;
@property (nonatomic, strong) MessageBubbleViewController *messageBubbleVC;

@end

@implementation BubbleChatViewController

- (instancetype)initWithUserID:(int64_t)userID andUserName:(NSString *)userName {
    self = [super initWithModeSwitchButton:NO];
    if (self) {
        self.navigationItem.title = userName;
        
        _userID = userID;
        _messageBubbleVC = [[MessageBubbleViewController alloc] initWithUserID:userID andUserName:userName];
        [self addChildViewController:_messageBubbleVC];
        [self.editingBar.sendButton addTarget:self action:@selector(sendComment) forControlEvents:UIControlEventTouchUpInside];
        
        [self setUpBlock];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (void)setUpBlock {
    __weak typeof(self) weakSelf = self;
    
    _messageBubbleVC.didScroll = ^ {
        [weakSelf.editingBar.editView resignFirstResponder];
    };
}

- (void)setLayout {
    [self.view addSubview:_messageBubbleVC.view];
    
    for (UIView *view in self.view.subviews) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    NSDictionary *views = @{@"messageBubbleTableView":_messageBubbleVC.view,@"editingBar":self.editingBar};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[messageBubbleTableView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[messageBubbleTableView][editingBar]" options:NSLayoutFormatAlignAllLeft | NSLayoutFormatAlignAllRight metrics:nil views:views]];

}

- (void)sendComment {
    [self.editingBar.editView resignFirstResponder];
    
    MBProgressHUD *HUD = [Utils createHUDInWindowOfView:self.view];
    if (self.editingBar.editView.text.length == 0) {
        HUD.mode = MBProgressHUDModeCustomView;
        HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
        HUD.labelText = @"内容不能为空";
        [HUD hide:YES afterDelay:1];
        return;
    }
    HUD.labelText = @"评论发送中";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
    
    [manager POST:[NSString stringWithFormat:@"%@%@", OSCAPI_PREFIX, OSCAPI_COMMENT_PUB]
       parameters:@{
                    @"uid":      @([Config getOwnID]),
                    @"receiver": @(_userID),
                    @"content":  [Utils convertRichTextToRawText:self.editingBar.editView]
                    }
     
          success:^(AFHTTPRequestOperation *operation, ONOXMLDocument *responseDocument) {
              ONOXMLElement *result = [responseDocument.rootElement firstChildWithTag:@"result"];
              int errorCode = [[[result firstChildWithTag:@"errorCode"] numberValue] intValue];
              NSString *errorMessage = [[result firstChildWithTag:@"errorMessage"] stringValue];
              
              HUD.mode = MBProgressHUDModeCustomView;
              
              if (errorCode == 1) {
                  self.editingBar.editView.text = @"";
                  
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-done"]];
                  HUD.labelText = @"发送留言成功";
              } else {
                  HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
                  HUD.labelText = [NSString stringWithFormat:@"错误：%@", errorMessage];
              }
              
              [HUD hide:YES afterDelay:1];
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              HUD.mode = MBProgressHUDModeCustomView;
              HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD-error"]];
              HUD.labelText = @"网络异常，留言发送失败";
              
              [HUD hide:YES afterDelay:1];
          }];
}

@end