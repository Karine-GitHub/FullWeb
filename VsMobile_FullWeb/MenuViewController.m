//
//  MenuViewController.m
//  VsMobile_FullWeb
//
//  Created by admin on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//
#import "AppDelegate.h"
#import "MenuViewController.h"
#import "IASKSettingsReader.h"


@interface MenuViewController ()

@end

@implementation MenuViewController {
    NSString *errorMsg;
    NSMutableDictionary *application;
    NSMutableArray *allPages;
    NSMutableArray *appDependencies;
    NSMutableArray *pageDependencies;
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //[[segue destinationViewController] setDetailItem:page];
}

- (void)setPageId:(id)NewPageId
{
    if (_PageId != NewPageId) {
        _PageId = NewPageId;
        
        // Update the view.
        [self configureView];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.Menu.delegate = self;
	// Do any additional setup after loading the view, typically from a nib.
    NSLog(@"The current device is : %@", [UIDevice currentDevice].model);
    
    AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSLog(@"Dl by Network : %hhd", appDel.isDownloadedByNetwork);
    NSLog(@"Dl by File : %hhd", appDel.isDownloadedByFile);
    
    // Get Application json file
    @try {
        if (appDel.isDownloadedByNetwork || appDel.isDownloadedByFile) {
            NSError *error = [[NSError alloc] init];
            application = (NSMutableDictionary *)[NSJSONSerialization JSONObjectWithData:APPLICATION_FILE options:NSJSONReadingMutableLeaves error:&error];
            if (application) {
                appDependencies = [application objectForKey:@"Dependencies"];
                allPages = [application objectForKey:@"Pages"];
                [self configureView];
            }
            else {
                NSLog(@"An error occured during the Loading of the Application : %@", error);
                // throw exception
                NSException *e = [NSException exceptionWithName:error.localizedDescription reason:error.localizedFailureReason userInfo:error.userInfo];
                @throw e;
            }
        }
        else {
            if (!appDel.isDownloadedByFile) {
                errorMsg = @"Impossible to download content file. The application will shut down. Sorry for the inconvenience.";
            } else if (!appDel.isDownloadedByNetwork) {
                errorMsg = @"Impossible to download content on the server. The network connection is too low or off. The application will shut down. Please try later.";
            }
            UIAlertView *alertNoConnection = [[UIAlertView alloc] initWithTitle:@"Application fails" message:errorMsg delegate:self cancelButtonTitle:@"Quit" otherButtonTitles:nil];
            [alertNoConnection show];
        }
    }
    @catch (NSException *e) {
        errorMsg = [NSString stringWithFormat:@"An error occured during the Loading of the Application : %@, reason : %@", e.name, e.reason];
        UIAlertView *alertNoConnection = [[UIAlertView alloc] initWithTitle:@"Application fails" message:errorMsg delegate:self cancelButtonTitle:@"Quit" otherButtonTitles:nil];
        [alertNoConnection show];
    }
}

- (void)configureView
{
    // Update the user interface for the Menu item.
    if (allPages) {
        for (NSMutableDictionary *page in allPages) {
            if ([[page objectForKey:@"isMenu"] isEqualToString:@"TRUE"]) {
                if (!_PageId) {
                    _PageId = [page objectForKey:@"Id"];
                }
                // Get Menu's Dependencies
                pageDependencies = [page objectForKey:@"Dependencies"];
                // Load Menu in the WebView
                if ([page objectForKey:@"HtmlContent"]) {
                    [self.Menu loadHTMLString:[self createHTML:[page objectForKey:@"HtmlContent"]] baseURL:[NSURL fileURLWithPath:APPLICATION_SUPPORT_PATH]];
                }
                else {
                    [self.Menu loadHTMLString:[self createHTML:@"<center><font color='blue'>There is no content</font></center>"] baseURL:[NSURL fileURLWithPath:APPLICATION_SUPPORT_PATH]];
                }
                self.AppName.text = [page objectForKey:@"Name"];
            }
        }
    }
}

- (NSMutableString *) addFiles
{
    NSMutableString *files;
    
    // INFO : ExtensionType is necessary when fileName does not contain an extension (i.e. js, css, json, ...). That's why it is commented
    if (appDependencies) {
        for (NSMutableDictionary *appDep in appDependencies) {
            if (![[appDep objectForKey:@"Name"] isKindOfClass:[NSNull class]] && ![[appDep objectForKey:@"Type"] isKindOfClass:[NSNull class]]) {
                //NSString *fileName = [NSString stringWithFormat:@"%@.%@", [appDep objectForKey:@"Name"], [AppDelegate extensionType:[appDep objectForKey:@"Type"]]];
                NSString *fileName = [NSString stringWithFormat:@"%@", [appDep objectForKey:@"Name"]];
                if ([[appDep objectForKey:@"Type"] isEqualToString:@"script"]) {
                    NSString *add = [NSString stringWithFormat:@"<script src='%@' type='text/javascript'></script>", fileName];
                    if (files) {
                        files = [NSMutableString stringWithFormat:@"%@%@", files, add];
                    } else {
                        files = (NSMutableString *)[NSString stringWithString:add];
                    }
                }
                if ([[appDep objectForKey:@"Type"] isEqualToString:@"style"]) {
                    NSString *add = [NSString stringWithFormat:@"<link type='text/css' rel='stylesheet' href='%@'></link>", fileName];
                    if (files) {
                        files = [NSMutableString stringWithFormat:@"%@%@", files, add];
                    } else {
                        files = (NSMutableString *)[NSString stringWithString:add];
                    }
                }
            }
        }
    }
    if (pageDependencies) {
        for (NSMutableDictionary *pageDep in pageDependencies) {
            if (![[pageDep objectForKey:@"Name"] isKindOfClass:[NSNull class]] && ![[pageDep objectForKey:@"Type"] isKindOfClass:[NSNull class]]) {
                //NSString *fileName = [NSString stringWithFormat:@"%@.%@", [pageDep objectForKey:@"Name"], [AppDelegate extensionType:[pageDep objectForKey:@"Type"]]];
                NSString *fileName = [NSString stringWithFormat:@"%@", [pageDep objectForKey:@"Name"]];
                if (![[pageDep objectForKey:@"Path"] isKindOfClass:[NSNull class]]) {
                    fileName = [NSString stringWithFormat:@"%@/%@", [pageDep objectForKey:@"Path"], [pageDep objectForKey:@"Name"]];
                }
                if ([[pageDep objectForKey:@"Type"] isEqualToString:@"script"]) {
                    NSString *add = [NSString stringWithFormat:@"<script src='%@' type='text/javascript'></script>", fileName];
                    if (files) {
                        files = [NSMutableString stringWithFormat:@"%@%@", files, add];
                    } else {
                        files = (NSMutableString *)[NSString stringWithString:add];
                    }
                    
                }
                if ([[pageDep objectForKey:@"Type"] isEqualToString:@"style"]) {
                    NSString *add = [NSString stringWithFormat:@"<link type='text/css' rel='stylesheet' href='%@'></link>", fileName];
                    if (files) {
                        files = [NSMutableString stringWithFormat:@"%@%@", files, add];
                    } else {
                        files = (NSMutableString *)[NSString stringWithString:add];
                    }
                }
            }
        }
    }
    return files;
}

- (NSString *)createHTML:(NSString *)htmlContent
{
    NSString *html = [NSString stringWithFormat:@"<!DOCTYPE>"
                      "<html>"
                      "<head>"
                      "%@"
                      "</head>"
                      "<body>"
                      "<div id='Main' style='padding:10px;'>"
                      "%@"
                      "</body>"
                      "</head>"
                      "</html>"
                      , [self addFiles], htmlContent];
    
    BOOL success = false;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = [[NSError alloc] init];
    NSString *path = [NSString stringWithFormat:@"%@%@.html", APPLICATION_SUPPORT_PATH, _PageId];
    NSData *content = [html dataUsingEncoding:NSUTF8StringEncoding];
    success = [fileManager createFileAtPath:path contents:content attributes:nil];
    if (!success) {
        NSLog(@"An error occured during the Saving of the html file : %@", error);
    }
    return html;
}

#pragma mark - Web View
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"fragment = %@", [request.URL fragment]);
    NSString *path = [APPLICATION_SUPPORT_PATH stringByReplacingOccurrencesOfString:@" " withString:@"\%20"];
    NSLog(@"Path = %@", path);
    
    // Test what item's menu is clicked for redirecting to the good page
    if ([[request.URL query] isEqual:_PageId]) {
        [self configureView];
    }
    else {
        self.showDetails = [[DetailsViewController alloc] init];
        [self.showDetails setDetailItem:[request.URL query]];
    }
    return YES;
}

- (void)webView:(UIWebView *)webview didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSString *errormsg = [NSString stringWithFormat:@"<html><center><font size=+4 color='red'>An error occured :<br>%@</font></center></html>", error.localizedDescription];
    [self.Menu loadHTMLString:[self createHTML:errormsg] baseURL:nil];
}

#pragma mark - Alert View
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        // Fermer l'application
        //Home button
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];
        // Wait while app is going background
        [NSThread sleepForTimeInterval:2.0];
        exit(0);
    }
}

#pragma mark IASKAppSettingsViewControllerDelegate protocol
- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    
    // Quit Settings view and show Menu view
    [self.appSettingsViewController dismissViewControllerAnimated:YES completion:^{
        [self presentViewController:self animated:YES completion:nil];
    }];
    // your code here to reconfigure the app for changed settings
}

#pragma mark kIASKAppSettingChanged notification
- (void)settingDidChange:(NSNotification*)notification {
    /*if ([notification.object isEqual:@"AutoConnect"]) {
     IASKAppSettingsViewController *activeController = self.tabBarController.selectedIndex ? self.tabAppSettingsViewController : self.appSettingsViewController;
     BOOL enabled = (BOOL)[[notification.userInfo objectForKey:@"AutoConnect"] intValue];
     [activeController setHiddenKeys:enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil] animated:YES];
     }*/
}

@end
