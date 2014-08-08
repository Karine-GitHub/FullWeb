//
//  MenuViewController.h
//  VsMobile_FullWeb
//
//  Created by admin on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IASKAppSettingsViewController.h"

@class DetailsViewController;

@interface MenuViewController : UIViewController <UIAlertViewDelegate, IASKSettingsDelegate, UITextViewDelegate, UISplitViewControllerDelegate, UIWebViewDelegate>

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;
@property (weak, nonatomic) IBOutlet UIWebView *Menu;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *Settings;

@end
