//
//  IXMessageControl.m
//  Ignite iOS Engine (IX)
//
//  Created by Jeremy Anticouni on 11/16/13.
//  Copyright (c) 2013 Apigee, Inc. All rights reserved.
//

/*  -----------------------------  */
//  [Documentation]
//
//  Author:     Jeremy Anticouni
//  Date:       1/29/2015
//
//  Copyright (c) 2015 Apigee. All rights reserved.
//
/*  -----------------------------  */
/**
 
 ###    Native iOS UI control that displays a menu from the bottom of the screen.
  
 <a href="#attributes">Attributes</a>,
 <a href="#readonly">Read-Only</a>,
 <a href="#inherits">Inherits</a>,
 <a href="#events">Events</a>,
 <a href="#functions">Functions</a>,
 <a href="#example">Example JSON</a>
 
 ##  <a name="attributes">Attributes</a>
 
 | Name                     | Type                                                   | Description                     | Default |
 |--------------------------|--------------------------------------------------------|---------------------------------|---------|
 | share.platform           | *facebook<br>twitter<br>flickr<br>vimeo<br>sina_weibo* | Where shall we share to?        |         |
 | share.text               | *(string)*                                             | What text do you want to share? |         |
 | share.url                | *(string)*                                             | Shall we share a URL?           |         |
 | share.image              | *(string)*                                             | Ducklips?                       |         |
 
 ##  <a name="inherits">Inherits</a>
 
>  IXBaseControl
 
##  <a name="readonly">Read Only Attributes</a>
 
 | Name                 | Type     | Description                      |
 |----------------------|----------|----------------------------------|
 | facebook_available   | *(bool)* | Is Facebook sharing available?   |
 | twitter_available    | *(bool)* | Is Twitter sharing available?    |
 | flickr_available     | *(bool)* | Is flickr sharing available?     |
 | vimeo_available      | *(bool)* | Is Vimeo sharing available?      |
 | sina_weibo_available | *(bool)* | Is Sina Weibo sharing available? |
 
 ##  <a name="events">Events</a>

 | Name                  | Description                                      |
 |-----------------------|--------------------------------------------------|
 | share_done            | Fires when shared successfully                   |
 | share_cancelled       | Fires if the user dismisses the view controller  |
 

 ##  <a name="functions">Functions</a>
 
Present Sharing view controller: *present_share_controller*

    {
      "_type": "Function",
      "on": "touch_up",
      "attributes": {
        "_target": "socialTest",
        "function_name": "present_share_controller"
      }
    }
 
Present Sharing view controller: *present_share_controller*

    {
      "_type": "Function",
      "on": "touch_up",
      "attributes": {
        "_target": "socialTest",
        "function_name": "present_share_controller"
      }
    }
 
 ##  <a name="example">Example JSON</a> 
 
 
 
 */
//
//  [/Documentation]
/*  -----------------------------  */

/*
 
 CONTROL
 
 - TYPE : "Message"
 
 - PROPERTIES
 
 * name=""        default=""               type="facebook, twitter, weibo"
 * name=""            default=""               type="String"
 * name=""             default=""               type="String"
 * name=""           default=""               type="String"
 
 - EVENTS
 
 * name="share_done"
 * name="share_cancelled"
 
 {
 "type": "Social",
 "properties": {
 "visible": "NO",
 "id": "myEmail",
 "width": "100%",
 "height": "50",
 "share": {
 "platform": "facebook",
 "text": "initial text goes here",
 "url": "http://google.com",
 "image": "/assets/images/social.jpg"
 },
 "color": {
 "background": "#00FFFF"
 }
 }
 },
 
 */

#import "IXSocial.h"

@import Social;

#import "IXAppManager.h"
#import "IXNavigationViewController.h"
#import "IXViewController.h"

#import "UIViewController+IXAdditions.h"
#import "NSString+IXAdditions.h"

#import "SDWebImageManager.h"

// Social Properties
static NSString* const kIX_SharePlatform = @"share.platform"; // kIX_SharePlatform Types Accepted
static NSString* const kIX_ShareText = @"share.text";
static NSString* const kIX_ShareImage = @"share.image";
static NSString* const kIX_ShareUrl = @"share.url";

// kIX_SharePlatform Types
static NSString* const kIX_SharePlatform_Facebook = @"facebook";
static NSString* const kIX_SharePlatform_Twitter = @"twitter";
static NSString* const kIX_SharePlatform_Flickr = @"flickr";
static NSString* const kIX_SharePlatform_Vimeo = @"vimeo";
static NSString* const kIX_SharePlatform_SinaWeibo = @"sina_weibo";

// Social Read-Only Properties
static NSString* const kIX_Facebook_Available = @"facebook_available";
static NSString* const kIX_Twitter_Available = @"twitter_available";
static NSString* const kIX_Flickr_Available = @"flickr_available";
static NSString* const kIX_Vimeo_Available = @"vimeo_available";
static NSString* const kIX_Sina_Weibo_Available = @"sina_weibo_available";

// Social Events
static NSString* const kIX_Share_Done = @"share_done";
static NSString* const kIX_Share_Cancelled = @"share_cancelled";

// Social Functions
static NSString* const kIX_Present_Share_Controller = @"present_share_controller"; // Params : "animated"
static NSString* const kIX_Dismiss_Share_Controller = @"dismiss_share_controller"; // Params : "animated"

@interface  IXSocial ()

@property (nonatomic,strong) SLComposeViewController* composeViewController;
@property (nonatomic,copy) SLComposeViewControllerCompletionHandler composeViewControllerCompletionBlock;

@property (nonatomic,strong) NSString* shareServiceType;
@property (nonatomic,strong) NSString* shareInitialText;
@property (nonatomic,strong) UIImage* shareImage;
@property (nonatomic,strong) NSURL* shareUrl;

@end

@implementation IXSocial

-(void)dealloc
{
    [self dismissComposeViewController:NO];
}

-(void)buildView
{
    __weak IXSocial* weakSelf = self;
    [self setComposeViewControllerCompletionBlock:^(SLComposeViewControllerResult result){
        switch (result)
        {
            case SLComposeViewControllerResultDone:
            {
                [[weakSelf actionContainer] executeActionsForEventNamed:kIX_Share_Done];
                break;
            }
            case SLComposeViewControllerResultCancelled:
            {
                [[weakSelf actionContainer] executeActionsForEventNamed:kIX_Share_Cancelled];
                break;
            }
            default:
            {
                break;
            }
        }
        [weakSelf dismissComposeViewController:YES];
    }];
}

-(void)applySettings
{
    [super applySettings];
    
    [self setShareServiceType:[IXSocial getServiceType:[[self propertyContainer] getStringPropertyValue:kIX_SharePlatform defaultValue:nil]]];
    [self setShareInitialText:[[self propertyContainer] getStringPropertyValue:kIX_ShareText defaultValue:nil]];

    [self setShareUrl:[NSURL URLWithString:[[self propertyContainer] getStringPropertyValue:kIX_ShareUrl defaultValue:nil]]];

    __weak IXSocial* weakSelf = self;
    [[self propertyContainer] getImageProperty:kIX_ShareImage
                                  successBlock:^(UIImage *image) {
                                      [weakSelf setShareImage:image];
                                  } failBlock:^(NSError *error) {
                                  }];
}

-(void)applyFunction:(NSString *)functionName withParameters:(IXPropertyContainer *)parameterContainer
{
    if( [functionName isEqualToString:kIX_Present_Share_Controller] )
    {
        BOOL animated = YES;
        if( parameterContainer ) {
            animated = [parameterContainer getBoolPropertyValue:kIX_ANIMATED defaultValue:animated];
        }
        [self presentComposeViewController:animated];
    }
    else if( [functionName isEqualToString:kIX_Dismiss_Share_Controller] )
    {
        BOOL animated = YES;
        if( parameterContainer ) {
            animated = [parameterContainer getBoolPropertyValue:kIX_ANIMATED defaultValue:animated];
        }
        [self dismissComposeViewController:animated];
    }
    else
    {
        [super applyFunction:functionName withParameters:parameterContainer];
    }
}

-(NSString*)getReadOnlyPropertyValue:(NSString *)propertyName
{
    NSString* returnValue = nil;
    if( [propertyName isEqualToString:kIX_Facebook_Available] )
    {
        returnValue = [NSString ix_stringFromBOOL:[SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]];
    }
    else if( [propertyName isEqualToString:kIX_Twitter_Available] )
    {
        returnValue = [NSString ix_stringFromBOOL:[SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]];
    }
    else if( [propertyName isEqualToString:kIX_Sina_Weibo_Available] )
    {
        returnValue = [NSString ix_stringFromBOOL:[SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]];
    }
    else
    {
        returnValue = [super getReadOnlyPropertyValue:propertyName];
    }
    return returnValue;
}

+(NSString*)getServiceType:(NSString*)typeSetting
{
    if( [typeSetting isEqualToString:kIX_SharePlatform_Twitter] )
        return SLServiceTypeTwitter;
    else if( [typeSetting isEqualToString:kIX_SharePlatform_Facebook] )
        return SLServiceTypeFacebook;
    else if( [typeSetting isEqualToString:kIX_SharePlatform_SinaWeibo] )
        return SLServiceTypeSinaWeibo;
    return nil;
}

-(void)dismissComposeViewController:(BOOL)animated
{
    if( [UIViewController isOkToDismissViewController:[self composeViewController]] )
    {
        [[self composeViewController] dismissViewControllerAnimated:animated completion:nil];
    }
}

-(void)presentComposeViewController:(BOOL)animated
{
    if( [self composeViewController] )
    {
        [self dismissComposeViewController:NO];
        [self setComposeViewController:nil];
    }

    if( [SLComposeViewController isAvailableForServiceType:[self shareServiceType]] )
    {
        [self setComposeViewController:[SLComposeViewController composeViewControllerForServiceType:[self shareServiceType]]];
        if( [self composeViewController] )
        {
            [[self composeViewController] setCompletionHandler:[self composeViewControllerCompletionBlock]];
            [[self composeViewController] setInitialText:[self shareInitialText]];
            [[self composeViewController] addImage:[self shareImage]];
            
            [[[IXAppManager sharedAppManager] rootViewController] presentViewController:[self composeViewController] animated:animated completion:nil];
        }
    }
}

@end
