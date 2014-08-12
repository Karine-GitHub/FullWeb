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
    NSString *queryString;
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

- (void)setPageId:(id)NewPageId
{
    if (_PageId != NewPageId) {
        _PageId = NewPageId;
        
        // Update the view.
        [self viewDidLoad];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.Menu.delegate = self;
    self.navigationItem.hidesBackButton = YES;
    
    AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSLog(@"Dl by Network : %hhd", appDel.isDownloadedByNetwork);
    NSLog(@"Dl by File : %hhd", appDel.isDownloadedByFile);
    
    // Get Application json file
    @try {
        if (appDel.isDownloadedByNetwork || appDel.isDownloadedByFile) {
            NSError *error = [[NSError alloc] init];
            application = (NSMutableDictionary *)[NSJSONSerialization JSONObjectWithData:APPLICATION_FILE options:NSJSONReadingMutableLeaves error:&error];
            if (application != nil) {
                appDependencies = [application objectForKey:@"Dependencies"];
                allPages = [application objectForKey:@"Pages"];
                // Set PageId
                for (NSMutableDictionary *page in allPages) {
                    if ([[page objectForKey:@"TemplateType"] isEqualToString:@"Menu"]) {
                        if (!_PageId) {
                            _PageId = [page objectForKey:@"Id"];
                        }
                    }
                }
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
    if (_PageId != nil) {
        @try {
            for (NSMutableDictionary *page in allPages) {
                if ([[page objectForKey:@"TemplateType"] isEqualToString:@"Menu"]) {
                    if (!_PageId) {
                        _PageId = [page objectForKey:@"Id"];
                    }
                    
                    // Get Menu's Dependencies
                    if ([page objectForKey:@"Dependencies"] != [NSNull null]) {
                        pageDependencies = [page objectForKey:@"Dependencies"];
                    }

                    NSURL *url = [NSURL fileURLWithPath:APPLICATION_SUPPORT_PATH isDirectory:YES];
                    // Load Menu in the WebView
                    if ([page objectForKey:@"HtmlContent"] != [NSNull null]) {
                        NSString *content = [AppDelegate createHTMLwithContent:[page objectForKey:@"HtmlContent"] withAppDep:appDependencies withPageDep:pageDependencies];
                        // Save HtmlContent in file
                        BOOL success = false;
                        NSFileManager *fileManager = [NSFileManager defaultManager];
                        NSError *error = [[NSError alloc] init];
                        NSString *path = [NSString stringWithFormat:@"%@index.html", APPLICATION_SUPPORT_PATH];
                        NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
                        success = [fileManager createFileAtPath:path contents:data attributes:nil];
                        if (!success) {
                            NSLog(@"An error occured during the Saving of the html file : %@", error);
                            NSException *e = [NSException exceptionWithName:error.localizedDescription reason:error.localizedFailureReason userInfo:error.userInfo];
                            @throw e;
                        }
                        
                        [self.Menu loadHTMLString:content baseURL:url];
                    }
                    else {
                        [self.Menu loadHTMLString:[AppDelegate createHTMLwithContent:@"<center><font color='blue'>There is no content</font></center>" withAppDep:nil withPageDep:nil] baseURL:url];
                    }
                    self.navigationItem.title = [page objectForKey:@"Title"];
                }
            }
        }
        @catch (NSException *exception) {
            errorMsg = [NSString stringWithFormat:@"An error occured during the Configuration of the view '%@' : %@, reason : %@", _PageId, exception.name, exception.reason];
            UIAlertView *alertNoConnection = [[UIAlertView alloc] initWithTitle:@"Application fails" message:errorMsg delegate:self cancelButtonTitle:@"Quit" otherButtonTitles:nil];
            [alertNoConnection show];
        }
    }
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
    NSLog(@"Query = %@", [request.URL query]);
    NSLog(@"Absolute string : %@   Absolute Url : %@", [request.URL absoluteString], [request.URL absoluteURL]);
    NSLog(@"Relative string : %@   Relative Path : %@", [request.URL relativeString], [request.URL relativePath]);
    NSLog(@"Path url : %@", [request.URL path]);
    
    int index = [APPLICATION_SUPPORT_PATH length] - 1;
    NSString *path = [APPLICATION_SUPPORT_PATH substringToIndex:index];
    NSLog(@"Path modifié = %@", path);
    
    if ([[request.URL relativePath] isEqualToString:path]) {
        // First loading
        return YES;
    } else if ([[request.URL relativePath] isEqualToString:[NSString stringWithFormat:@"%@index.html", APPLICATION_SUPPORT_PATH]]) {
        return YES;
    } else if ([request.URL query] != nil) {
        queryString = [request.URL query];
        self.showDetails = [self.storyboard instantiateViewControllerWithIdentifier:@"detailsView"];
        self.showDetails.detailItem = queryString;
        [self.showDetails setGoBack:_PageId];
        [self.navigationController pushViewController:self.showDetails animated:YES];
        return YES;
    }
    return NO;
}

- (void)webView:(UIWebView *)webview didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    errorMsg = [NSString stringWithFormat:@"<html><center><font size=+4 color='red'>An error occured :<br>%@</font></center></html>", error.localizedDescription];
    [self.Menu loadHTMLString:[AppDelegate createHTMLwithContent:errorMsg withAppDep:nil withPageDep:nil] baseURL:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"changeView"]) {
        DetailsViewController *details = (DetailsViewController *)[[segue destinationViewController] visibleViewController];
        [details setDetailItem:queryString];
    }
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
    [self configureView];
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
