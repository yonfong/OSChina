//
//  OSCComment.m
//  OSChina
//
//  Created by sky on 15/7/1.
//  Copyright (c) 2015年 bluesky. All rights reserved.
//

#import "OSCComment.h"

static NSString * const kID       = @"id";
static NSString * const kPortrait = @"portrait";
static NSString * const kAuthor   = @"author";
static NSString * const kAuthorID = @"authorid";
static NSString * const kContent  = @"content";
static NSString * const kPubDate  = @"pubDate";
static NSString * const kReplies  = @"replies";
static NSString * const kReply    = @"reply";
static NSString * const kRefers   = @"refers";
static NSString * const kRefer    = @"refer";
static NSString * const kRauthor  = @"rauthor";
static NSString * const kRContent = @"rcontent";

@implementation OSCComment

- (instancetype)initWithXML:(ONOXMLElement *)xml
{
    if (self = [super init]) {
        _commentID                     = [[[xml firstChildWithTag:kID] numberValue] longLongValue];
        _authorID                      = [[[xml firstChildWithTag:kAuthorID] numberValue] longLongValue];

        _portraitURL                   = [NSURL URLWithString:[[xml firstChildWithTag:kPortrait] stringValue]];
        _author                        = [[xml firstChildWithTag:kAuthor] stringValue];

        _content                       = [[xml firstChildWithTag:kContent] stringValue];
        _pubDate                       = [[xml firstChildWithTag:kPubDate] stringValue];

        NSMutableArray *mutableReplies = [NSMutableArray new];
        NSArray *repliesXML            = [[xml firstChildWithTag:kReplies] childrenWithTag:kReply];
        for (ONOXMLElement *replyXML in repliesXML) {
            OSCReply *reply = [[OSCReply alloc] initWithXML:replyXML];
            [mutableReplies addObject:reply];
        }
        _replies                       = [NSArray arrayWithArray:mutableReplies];
    
        NSMutableArray *mutableReferences = [NSMutableArray new];
        NSArray *refersXML = [[xml firstChildWithTag:kRefers] childrenWithTag:kRefer];
        for (ONOXMLElement *referXML in refersXML) {
            OSCReference *reference = [[OSCReference alloc] initWithXML:referXML];
            [mutableReferences addObject:reference];
        }
        _references = [NSArray arrayWithArray:mutableReferences];
    }
    
    return self;
}


@end
