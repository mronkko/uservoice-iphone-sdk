//
//  UVWelcomeViewController.m
//  UserVoice
//
//  Created by UserVoice on 12/15/09.
//  Copyright 2009 UserVoice Inc. All rights reserved.
//

#include <QuartzCore/QuartzCore.h>
#import "UVRootViewController.h"
#import "UVClientConfig.h"
#import "UVAccessToken.h"
#import "UVRequestToken.h"
#import "UVSession.h"
#import "UVUser.h"
#import "UVWelcomeViewController.h"
#import "UVSuggestionListViewController.h"
#import "UVNewTicketViewController.h"
#import "UVConfig.h"
#import "UVStyleSheet.h"
#import "UVNewSuggestionViewController.h"
#import "UVInitialLoadManager.h"
#import "UVArticle.h"
#import "UVArticleViewController.h"
#import "UVHelpTopic.h"
#import "UVHelpTopicViewController.h"

@implementation UVRootViewController

@synthesize viewToLoad;
@synthesize loader;

- (id)init {
    if (self = [super init]) {
        self.viewToLoad = @"welcome";
    }
    return self;
}

- (id)initWithViewToLoad:(NSString *)theViewToLoad {
    if (self = [super init]) {
        self.viewToLoad = theViewToLoad;
    }
    return self;
}

- (void)dismissUserVoice {
    loader.dismissed = YES;
    [super dismissUserVoice];
}

- (void)pushNextView {
    UVSession *session = [UVSession currentSession];
    if ((![UVAccessToken exists] || session.user) && session.clientConfig && [self.navigationController.viewControllers count] == 1) {
        UVBaseViewController *next = nil;
        
        NSInteger articleId = [self.viewToLoad integerValue];
        
        // Article ID was not set
        
        if(articleId==0){
            if ([self.viewToLoad isEqualToString:@"welcome"])
                next = [[[UVWelcomeViewController alloc] init] autorelease];
            else if ([self.viewToLoad isEqualToString:@"suggestions"])
                next = [[[UVSuggestionListViewController alloc] init] autorelease];
            else if ([self.viewToLoad isEqualToString:@"new_suggestion"])
                next = [UVNewSuggestionViewController viewController];
            else if ([self.viewToLoad isEqualToString:@"new_ticket"])
                next = [UVNewTicketViewController viewController];
         
            [self pushViewsAndAnimate:[NSArray arrayWithObject:next]];
        }

        // Article ID is set, load article
        
        else{
            [UVArticle getArticleWithId:articleId delegate:self];
        }
        
    }
}

- (void)pushViewsAndAnimate:(NSArray*) viewControllers {
    CATransition* transition = [CATransition animation];
    transition.duration = 0.3;
    transition.type = kCATransitionFade;
    [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];

    BOOL first = TRUE;
    
    for(UVBaseViewController* viewController in viewControllers){
        viewController.firstController = first;
        first = FALSE;
        [self.navigationController pushViewController:viewController animated:NO];
    }
}

-(void) didRetrieveArticle:(UVArticle*) article{

    UVArticleViewController *articleViewController = [[[UVArticleViewController alloc] initWithArticle:article helpfulPrompt:nil returnMessage:nil] autorelease];
        
    // Construct a view controller array consisting welcome VC and article VC
    
     UIViewController *welcomeViewController = [[[UVWelcomeViewController alloc] init] autorelease];
     
     UVHelpTopic *selectedTopic = nil;

    for(UVHelpTopic* topic in [UVSession currentSession].topics){
        if(topic.topicId == article.topicId){
            selectedTopic = topic;
            break;
        }
    }

    if(selectedTopic != nil){
        UVHelpTopicViewController *topicViewController = [[[UVHelpTopicViewController alloc] initWithTopic:selectedTopic] autorelease];
        [topicViewController loadView];
        
        [self pushViewsAndAnimate:[NSArray arrayWithObjects:welcomeViewController, topicViewController, articleViewController, nil]];
    }
    else{
        [self pushViewsAndAnimate:[NSArray arrayWithObjects:welcomeViewController, articleViewController, nil]];        
    }

}

#pragma mark ===== Basic View Methods =====

- (void)loadView {
    [super loadView];

    self.navigationItem.title = NSLocalizedStringFromTable(@"Feedback & Support", @"UserVoice", nil);
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Close", @"UserVoice", nil)
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(dismissUserVoice)] autorelease];

    self.view = [[[UIView alloc] initWithFrame:[self contentFrame]] autorelease];
    self.view.backgroundColor = [UVStyleSheet backgroundColor];

    UIView *loading = [[[UIView alloc] initWithFrame:CGRectMake(0, 120, self.view.bounds.size.width, 100)] autorelease];
    loading.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin;
    UIActivityIndicatorView *activity = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    if ([activity respondsToSelector:@selector(setColor:)]) {
        [activity setColor:[UIColor grayColor]];
    } else {
        activity = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
    }
    activity.center = CGPointMake(loading.bounds.size.width/2, 40);
    [loading addSubview:activity];
    [activity startAnimating];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 70, loading.frame.size.width, 20)] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = [UIColor darkGrayColor];
    label.textAlignment = UITextAlignmentCenter;
    label.text = NSLocalizedStringFromTable(@"Loading...", @"UserVoice", nil);
    [label sizeToFit];
    label.center = CGPointMake(loading.bounds.size.width/2, 85);
    [loading addSubview:label];
    [loading sizeToFit];
    [self.view addSubview:loading];
}

- (void)viewWillAppear:(BOOL)animated {
    self.loader = [UVInitialLoadManager loadWithDelegate:self action:@selector(pushNextView)];
}

- (void)dealloc {
    self.viewToLoad = nil;
    self.loader = nil;
    [super dealloc];
}

@end
