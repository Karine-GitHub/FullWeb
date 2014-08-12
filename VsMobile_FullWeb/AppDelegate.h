//
//  AppDelegate.h
//  VsMobile_FullWeb
//
//  Created by admin on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "MenuViewController.h"

// GLOBAL VARIABLES json files
extern NSData *APPLICATION_FILE;
extern NSData *FEED_FILE;
// END GLOBAL VARIABLES

extern NSString *APPLICATION_SUPPORT_PATH;


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSMutableDictionary *application;
@property BOOL isDownloadedByNetwork;
@property BOOL isDownloadedByFile;

+ (BOOL) testConnection;
+ (BOOL) testFastConnection;
+ (NSString *) extensionType:(NSString *)type;
+ (NSMutableString *) addFiles:(NSArray *)dependencies;
+ (NSString *)createHTMLwithContent:(NSString *)htmlContent withAppDep:(NSArray *)appDep withPageDep:(NSArray *)pageDep;

@end
