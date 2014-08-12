//
//  MenuViewController.h
//  VsMobile_FullWeb
//
//  Created by admin on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IASKAppSettingsViewController.h"

#import "DetailsViewController.h"

@interface MenuViewController : UIViewController <UIAlertViewDelegate, IASKSettingsDelegate, UITextViewDelegate, UISplitViewControllerDelegate, UIWebViewDelegate>

@property (strong, nonatomic) id PageId;

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;

@property (weak, nonatomic) IBOutlet UIWebView *Menu;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *Settings;

@property (nonatomic,retain) DetailsViewController *showDetails;

@end
