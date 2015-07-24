//
//  Utils.m
//  iosapp
//
//  Created by chenhaoxiang on 14-10-16.
//  Copyright (c) 2014年 oschina. All rights reserved.
//


#import <SDWebImage/UIImageView+WebCache.h>
#import "Utils.h"
#import "OSCTweet.h"
#import "OSCNews.h"
#import "OSCBlog.h"
#import "OSCPost.h"
#import "UserDetailsViewController.h"
#import "DetailsViewController.h"
#import "PostsViewController.h"
#import "TweetDetailsWithBottomBarViewController.h"
#import "ImageViewController.h"
#import <objc/runtime.h>
#import <Reachability.h>

@implementation Utils


#pragma mark - 处理API返回信息

+ (NSAttributedString *)getAppclient:(int)clientType
{
    NSMutableAttributedString *clientString = [NSMutableAttributedString new];
    if (clientType > 1 && clientType <= 6) {
        NSTextAttachment *textAttachment = [NSTextAttachment new];
        textAttachment.image = [UIImage imageNamed:@"phone"];
        [textAttachment adjustY:-2];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:textAttachment];
        [clientString appendAttributedString:attachmentString];

        NSArray *clients = @[@"", @"", @"手机", @"Android", @"iPhone", @"Windows Phone", @"微信"];
        [clientString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        [clientString appendAttributedString:[[NSAttributedString alloc] initWithString:clients[clientType]]];
    } else {
        [clientString appendAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    }
    
    return clientString;
}

+ (NSString *)generateRelativeNewsString:(NSArray *)relativeNews
{
    if (relativeNews == nil || [relativeNews count] == 0) {
        return @"";
    }
    
    NSString *middle = @"";
    for (NSArray *news in relativeNews) {
        middle = [NSString stringWithFormat:@"%@<a href=%@ style='text-decoration:none'>%@</a><p/>", middle, news[1], news[0]];
    }
    return [NSString stringWithFormat:@"<hr/>相关文章<div style='font-size:14px'><p/>%@</div>", middle];
}

+ (NSString *)GenerateTags:(NSArray *)tags
{
    if (tags == nil || tags.count == 0) {
        return @"";
    } else {
        NSString *result = @"";
        for (NSString *tag in tags) {
            result = [NSString stringWithFormat:@"%@<a style='background-color: #BBD6F3;border-bottom: 1px solid #3E6D8E;border-right: 1px solid #7F9FB6;color: #284A7B;font-size: 12pt;-webkit-text-size-adjust: none;line-height: 2.4;margin: 2px 2px 2px 0;padding: 2px 4px;text-decoration: none;white-space: nowrap;' href='http://www.oschina.net/question/tag/%@' >&nbsp;%@&nbsp;</a>&nbsp;&nbsp;", result, tag, tag];
        }
        return result;
    }
}

+ (void)analysis:(NSString *)url andNavController:(UINavigationController *)navigationController {
    //判断是否包含 oschina.net 来确定是不是站内链接
    NSRange range = [url rangeOfString:@"oschina.net"];
    if (range.length <= 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    } else {
        //站内链接
        
        url = [url substringFromIndex:7];
        NSArray *pathComponents = [url pathComponents];
        NSString *prefix = [pathComponents[0] componentsSeparatedByString:@"."][0];
        UIViewController *viewController;
        
        if ([prefix isEqualToString:@"my"]) {
            
            if (pathComponents.count == 2) {
                //个人专页 my.oschina.net/dong706
                viewController = [[UserDetailsViewController alloc] initWithUserName:pathComponents[1]];
                viewController.navigationItem.title = @"用户详情";
            } else if (pathComponents.count == 3) {
                //个人专页 my.oschina.net/u/12
                if ([pathComponents[1] isEqualToString:@"u"]) {
                    viewController = [[UserDetailsViewController alloc] initWithUserID:[pathComponents[2] longLongValue]];
                    viewController.navigationItem.title = @"用户详情";
                }
            } else if (pathComponents.count == 4) {
                NSString *type = pathComponents[2];
                if ([type isEqualToString:@"blog"]) {
                    OSCNews *news = [OSCNews new];
                    news.type = NewsTypeBlog;
                    news.attachment = pathComponents[3];
                    viewController = [[DetailsViewController alloc] initWithNews:news];
                    viewController.navigationItem.title = @"博客详情";
                } else if ([type isEqualToString:@"tweet"]) {
                    OSCTweet *tweet = [OSCTweet new];
                    tweet.tweetID = [pathComponents[3] longLongValue];
                    viewController = [[TweetDetailsWithBottomBarViewController alloc] initWithTweetID:tweet.tweetID];
                    viewController.navigationItem.title = @"动弹详情";
                }
            } else if (pathComponents.count == 5) {
                NSString *type = pathComponents[3];
                if ([type isEqualToString:@"blog"]) {
                    OSCNews *news = [OSCNews new];
                    news.type = NewsTypeBlog;
                    news.attachment = pathComponents[4];
                    viewController = [[DetailsViewController alloc] initWithNews:news];
                    viewController.navigationItem.title = @"博客详情";
                }
            }
        } else if ([prefix isEqualToString:@"www"]) {
            //新闻、软件、问答
            NSArray *urlComponents = [url componentsSeparatedByString:@"/"];
            NSUInteger count = urlComponents.count;
            if (count >= 3) {
                NSString *type = urlComponents[1];
                if ([type isEqualToString:@"news"]) {
                    //新闻
                    //www.oschina.net/news/27259/mobile-internet-market-is-small
                    
                    int64_t newsID = [urlComponents[2] longLongValue];
                    OSCNews *news = [OSCNews new];
                    news.type = NewsTypeStandardNews;
                    news.newsID = newsID;
                    viewController = [[DetailsViewController alloc] initWithNews:news];
                    viewController.navigationItem.title = @"资讯详情";
                } else if ([type isEqualToString:@"p"]) {
                    //软件 www.oschina.net/p/jx
                    OSCNews *news = [OSCNews new];
                    news.type = NewsTypeSoftWare;
                    news.attachment = urlComponents[2];
                    viewController = [[DetailsViewController alloc] initWithNews:news];
                    viewController.navigationItem.title = @"软件详情";
                } else if ([type isEqualToString:@"question"]) {
                    //问答
                    if (count == 3) {
                        //问答 www.oschina.net/question/12_45738
                        NSArray *IDs = [urlComponents[2] componentsSeparatedByString:@"_"];
                        if (IDs.count >= 2) {
                            OSCPost *post = [OSCPost new];
                            post.postID = [IDs[1] longLongValue];
                            viewController = [[DetailsViewController alloc] initWithPost:post];
                            viewController.navigationItem.title = @"帖子详情";
                        } else if (IDs.count == 4) {
                            //问答-标签 www.oschina.net/question/tag/python
                            
                            NSString *tag = urlComponents.lastObject;
                            
                            viewController = [PostsViewController new];
                            ((PostsViewController *)viewController).generateURL = ^NSString *(NSUInteger page) {
                                return [NSString stringWithFormat:@"%@%@?tag=%@&pageIndex=0&%@", OSCAPI_PREFIX, OSCAPI_POSTS_LIST, tag, OSCAPI_SUFFIX];
                            };
                            ((PostsViewController *)viewController).objClass = [OSCPost class];
                            viewController.navigationItem.title = [tag stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        }
                    }
                }
            }
        } else if ([prefix isEqualToString:@"static"]) {

            ImageViewController *imageViewerVC = [[ImageViewController alloc] initWithImageURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url]]];
            [navigationController presentViewController:imageViewerVC animated:YES completion:nil];
           return;

        }
        
        if (viewController) {
            [navigationController pushViewController:viewController animated:YES];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", url]]];
        }
        
    }
}

#pragma mark - 通用

#pragma mark - 信息处理

+ (NSDictionary *)timeIntervalArrayFromString:(NSString *)dateStr {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *date = [dateFormatter dateFromString:dateStr];
    
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *compsPast = [calendar components:unitFlags fromDate:date];
    NSDateComponents *compsNow = [calendar components:unitFlags fromDate:[NSDate date]];
    
    NSInteger years = compsNow.year - compsPast.year;
    NSInteger months = compsNow.month - compsPast.month + years * 12;
    NSInteger days = compsNow.day - compsPast.day + months * 30;
    NSInteger hours = compsNow.hour - compsPast.hour + days * 24;
    NSInteger minutes = compsNow.minute - compsPast.minute + hours * 60;
    
    return @{
             kKeyYears: @(years),
             kKeyMonths: @(months),
             kKeyDays: @(days),
             kKeyHours: @(hours),
             kKeyMinutes:@(minutes)
             };
}

+ (NSDateComponents *)getDateComponentsFromDate:(NSDate *)date {
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    return [calendar components:unitFlags fromDate:date];
}

+ (NSString *)getWeekdayFromDateComponents:(NSDateComponents *)dateComps {
    switch (dateComps.weekday) {
        case 1: return @"星期天";
        case 2: return @"星期一";
        case 3: return @"星期二";
        case 4: return @"星期三";
        case 5: return @"星期四";
        case 6: return @"星期五";
        case 7: return @"星期六";
        default: return @"";
    }
}


+ (NSAttributedString *)attributedTimeString:(NSString *)dateStr {
    NSMutableAttributedString *attributedTime;
    
    NSTextAttachment *textAttachment = [NSTextAttachment new];
    textAttachment.image = [UIImage imageNamed:@"time"];
    [textAttachment adjustY:-1];
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:textAttachment];
    attributedTime = [[NSMutableAttributedString alloc] initWithAttributedString:attachmentString];
    [attributedTime appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [attributedTime appendAttributedString:[[NSAttributedString alloc] initWithString:[self intervalSinceNow:dateStr]]];
    
    return attributedTime;
}

+ (NSAttributedString *)attributedCommentCount:(int)commentCount {
    NSMutableAttributedString *attributedCommentCount;

    NSTextAttachment *textAttachment = [NSTextAttachment new];
    textAttachment.image = [UIImage imageNamed:@"comment"];
    [textAttachment adjustY:-2];

    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:textAttachment];
    attributedCommentCount = [[NSMutableAttributedString alloc] initWithAttributedString:attachmentString];
    [attributedCommentCount appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [attributedCommentCount appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", commentCount]]];
    
    return attributedCommentCount;
}

+ (NSString *)intervalSinceNow:(NSString *)dateStr
{
    NSDictionary *dic = [Utils timeIntervalArrayFromString:dateStr];
    //NSInteger years = [[dic objectForKey:kKeyYears] integerValue];
    NSInteger months = [[dic objectForKey:kKeyMonths] integerValue];
    NSInteger days = [[dic objectForKey:kKeyDays] integerValue];
    NSInteger hours = [[dic objectForKey:kKeyHours] integerValue];
    NSInteger minutes = [[dic objectForKey:kKeyMinutes] integerValue];
    
    if (minutes < 1) {
        return @"刚刚";
    } else if (minutes < 60) {
        return [NSString stringWithFormat:@"%ld分钟前", (long)minutes];
    } else if (hours < 24) {
        return [NSString stringWithFormat:@"%ld小时前", (long)hours];
    } else if (hours < 48 && days == 1) {
        return @"昨天";
    } else if (days < 30) {
        return [NSString stringWithFormat:@"%ld天前", (long)days];
    } else if (days < 60) {
        return @"一个月前";
    } else if (months < 12) {
        return [NSString stringWithFormat:@"%ld个月前", (long)months];
    } else {
        NSArray *arr = [dateStr componentsSeparatedByString:@"T"];
        return arr.firstObject;
    }
}

// 参考 http://www.cnblogs.com/ludashi/p/3962573.html
+ (NSAttributedString *)emojiStringFromRawString:(NSString *)rawString {
    NSMutableAttributedString *emojiString = [[NSMutableAttributedString alloc] initWithString:rawString];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"emoji" ofType:@"plist"];
    NSDictionary *emoji = [[NSDictionary alloc] initWithContentsOfFile:path];
    
    NSString *pattern = @"\\[[a-zA-Z0-9\\u4e00-\\u9fa5]+\\]|:[a-zA-Z0-9\\u4e00-\\u9fa5_]+:";
    NSError *error = nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSArray *resultsArray = [re matchesInString:rawString options:0 range:NSMakeRange(0, rawString.length)];
    
    NSMutableArray *emojiArray = [NSMutableArray arrayWithCapacity:resultsArray.count];
    
    for (NSTextCheckingResult *math in resultsArray) {
        NSRange range = [math range];
        NSString *emojiName = [rawString substringWithRange:range];
        
        if ([emojiName hasPrefix:@"["] && emoji[emojiName]) {
                NSTextAttachment *textAttachment = [NSTextAttachment new];
                textAttachment.image = [UIImage imageNamed:emoji[emojiName]];
                NSAttributedString *emojiAttributedString = [NSAttributedString attributedStringWithAttachment:textAttachment];
                NSDictionary *emojiToReplace = @{@"image": emojiAttributedString, @"range": [NSValue valueWithRange:range]};
                [emojiArray addObject:emojiToReplace];
        } else if ([emojiName hasPrefix:@":"] && emoji[emojiName]) {
            NSDictionary *emojiToReplace = @{@"text": emoji[emojiName], @"range": [NSValue valueWithRange:range]};
            [emojiArray addObject:emojiToReplace];
        }
    }
    
    for (NSInteger i = emojiArray.count - 1; i >= 0; i--) {
        NSRange range;
        [emojiArray[i][@"range"] getValue:&range];
        if (emojiArray[i][@"image"]) {
            [emojiString replaceCharactersInRange:range withAttributedString:emojiArray[i][@"image"]];
        } else {
            [emojiString replaceCharactersInRange:range withString:emojiArray[i][@"text"]];
        }
    }
    
    return emojiString;
}

+ (NSData *)compressImage:(UIImage *)image {
    CGSize size = [self scaleSize:image.size];
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSUInteger maxFileSize = 500*1024;
    CGFloat compressRatio = 0.7f;
    CGFloat maxCompressionRatio = 0.1f;
    
    NSData *imageData = UIImageJPEGRepresentation(scaledImage, compressRatio);
    while (imageData.length > maxFileSize && compressRatio > maxCompressionRatio) {
        compressRatio -= 0.1f;
        
        imageData = UIImageJPEGRepresentation(image, compressRatio);
    }
    
    return imageData;
}

+ (CGSize)scaleSize:(CGSize)sourceSize {
    float width = sourceSize.width;
    float height = sourceSize.height;
    if (width >= height) {
        return CGSizeMake(800, 800 * height / width);
    } else {
        return CGSizeMake(800 * width / height, 800);
    }
}

+ (NSString *)escapeHTML:(NSString *)originalHTML {
    if (!originalHTML) {
        return @"";
    }
    
    NSMutableString *result = [[NSMutableString alloc] initWithString:originalHTML];
    [result replaceOccurrencesOfString:@"&"  withString:@"&amp;"  options:NSLiteralSearch range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"<"  withString:@"&lt;"   options:NSLiteralSearch range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@">"  withString:@"&gt;"   options:NSLiteralSearch range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [result length])];
    [result replaceOccurrencesOfString:@"'"  withString:@"&#39;"  options:NSLiteralSearch range:NSMakeRange(0, [result length])];
    
    return result;
}

+ (NSString *)convertRichTextToRawText:(UITextView *)textView {
    NSMutableString *rawText = [[NSMutableString alloc] initWithString:textView.text];
    [textView.attributedText enumerateAttribute:NSAttachmentAttributeName inRange:NSMakeRange(0, textView.text.length) options:NSAttributedStringEnumerationReverse usingBlock:^(NSTextAttachment *attachment, NSRange range, BOOL *stop) {
        if (!attachment) {
            return ;
        }
        
        int emojiNum = [objc_getAssociatedObject(attachment, @"number") intValue];
        [rawText insertString:[NSString stringWithFormat:@"[%d]",emojiNum-1] atIndex:range.location];
    }];
    
    NSString *pattern = @"[\ue000-\uf8ff]|[\\x{1f300}-\\x{1f7ff}]|\\x{263A}\\x{FE0F}|☺";
    NSError *error = nil;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];

    NSArray *resultsArray = [re matchesInString:textView.text options:0 range:NSMakeRange(0, textView.text.length)];

    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"emojiToText" ofType:@"plist"];
    NSDictionary *emojiToText = [[NSDictionary alloc] initWithContentsOfFile:path];

    for (NSTextCheckingResult *match in [resultsArray reverseObjectEnumerator]) {
        NSString *emoji = [textView.text substringWithRange:match.range];
        [rawText replaceCharactersInRange:match.range withString:emojiToText[emoji]];
    }
    
    return [rawText stringByReplacingOccurrencesOfString:@"\U0000fffc" withString:@""];
}

+ (BOOL)isURL:(NSString *)string {
    NSString *pattern = @"^(http|https)://.*?$(net|com|.com.cn|org|me|)";
    NSPredicate *urlPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [urlPredicate evaluateWithObject:string];
}

+ (NSInteger)networkStatus {
    Reachability *reachability = [Reachability reachabilityWithHostName:@"www.oschina.net"];
    return reachability.currentReachabilityStatus;
}

+ (BOOL)isNetworkExitst {
    return [self networkStatus] > 0;
}

#pragma mark - UI处理

+ (void)roundView:(UIView *)view cornerRadius:(CGFloat)cornerRadius
{
    view.layer.cornerRadius = cornerRadius;
    view.layer.masksToBounds = YES;
}

+ (CGFloat)valueBetweenMin:(CGFloat)min andMax:(CGFloat)max percent:(CGFloat)percent
{
    return min + (max - min) * percent;
}

+ (MBProgressHUD *)createHUD {
    UIWindow *window = [[UIApplication sharedApplication].windows lastObject];
    MBProgressHUD *hub = [[MBProgressHUD alloc] initWithWindow:window];
    hub.detailsLabelFont = [UIFont boldSystemFontOfSize:16];
    [window addSubview:hub];
    [hub show:YES];
    
    return hub;
}

+ (UIImage *)createQRCodeFromString:(NSString *)string {
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    CIFilter *QRFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    [QRFilter setValue:stringData forKey:@"inputMessage"];
    [QRFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    CGFloat scale = 5;
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:QRFilter.outputImage fromRect:QRFilter.outputImage.extent];
    
    //Scale the image usign CoreGraphics
    CGFloat width = QRFilter.outputImage.extent.size.width * scale;
    UIGraphicsBeginImageContext(CGSizeMake(width, width));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    //Cleaning up
    UIGraphicsEndImageContext();
    CGImageRelease(cgImage);
    
    return image;
}


@end
