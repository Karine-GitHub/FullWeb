//
//  DetailsViewController.m
//  VsMobile_FullWeb
//
//  Created by admin on 8/8/14.
//  Copyright (c) 2014 admin. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailsViewController.h"

@interface DetailsViewController ()

@end

@implementation DetailsViewController {
    MenuViewController *Menu;
    NSMutableDictionary *application;
    NSMutableArray *allPages;
    NSMutableArray *appDependencies;
    NSMutableArray *pageDependencies;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.Details.delegate = self;
    // Get Application's Dependencies
    @try {
        NSError *error = [[NSError alloc] init];
        application = (NSMutableDictionary *)[NSJSONSerialization JSONObjectWithData:APPLICATION_FILE options:NSJSONReadingMutableLeaves error:&error];
        if (!application) {
            NSLog(@"An error occured during the Deserialization of Application file : %@", error);
            // Throw exception
            NSException *e = [NSException exceptionWithName:error.localizedDescription reason:error.localizedFailureReason userInfo:error.userInfo];
            @throw e;
        }
        else {
            if ([application objectForKey:@"Dependencies"]) {
                appDependencies = [application objectForKey:@"Dependencies"];
                allPages = [application objectForKey:@"Pages"];
                [self configureView];
                self.navigationItem.backBarButtonItem.title = [application objectForKey:@"Name"];
            }
        }
    }
    @catch  (NSException *e) {
        _errorMsg = [NSString stringWithFormat:@"An error occured during the Loading of the Application : %@, reason : %@", e.name, e.reason];
        UIAlertView *alertNoConnection = [[UIAlertView alloc] initWithTitle:@"Application fails" message:_errorMsg delegate:self cancelButtonTitle:@"Quit" otherButtonTitles:nil];
        [alertNoConnection show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)configureView
{
    // Update the user interface for the detail item.
    
    if (self.detailItem) {
        for (NSMutableDictionary *details in allPages) {
            if ([[details objectForKey:@"Id"] isEqualToNumber:self.detailItem]) {
                // Get Page's Dependencies
                if ([details objectForKey:@"Dependencies"]) {
                    pageDependencies = [self.detailItem objectForKey:@"Dependencies"];
                }
                
                // Load Content in the WebView
                if ([details objectForKey:@"HtmlContent"]) {
                    // Contact page already contains all Html.
                    if ([[details objectForKey:@"Name"] isEqualToString:@"Contact"]) {
                        [self.Details loadHTMLString:[details objectForKey:@"HtmlContent"] baseURL:[NSURL fileURLWithPath:APPLICATION_SUPPORT_PATH]];
                    }
                    else {
                        [self.Details loadHTMLString:[self createHTML:[details objectForKey:@"HtmlContent"]] baseURL:[NSURL fileURLWithPath:APPLICATION_SUPPORT_PATH]];
                    }
                }
                else {
                    [self.Details loadHTMLString:[self createHTML:@"<center><font color='blue'>There is no content</font></center>"] baseURL:[NSURL fileURLWithPath:APPLICATION_SUPPORT_PATH]];
                }
                
                // Set Page's title
                if (![self.detailItem objectForKey:@"Name"]) {
                    self.AppName.text = @"No Name property";
                }
                else {
                    self.AppName.text = [application objectForKey:@"Name"];
                }
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
    NSString *path = [NSString stringWithFormat:@"%@%@.html", APPLICATION_SUPPORT_PATH, self.detailItem];
    NSData *content = [html dataUsingEncoding:NSUTF8StringEncoding];
    success = [fileManager createFileAtPath:path contents:content attributes:nil];
    if (!success) {
        NSLog(@"An error occured during the Saving of the html file : %@", error);
    }
    return html;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
    
    if (![[request.URL query] isEqual:self.detailItem]) {
        [self configureView];
    }
    else {
        Menu = [[MenuViewController alloc]init];
        [Menu setPageId:[request.URL query]];
    }
    return YES;
}

- (void)webView:(UIWebView *)webview didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSString *errormsg = [NSString stringWithFormat:@"<html><center><font size=+4 color='red'>An error occured :<br>%@</font></center></html>", error.localizedDescription];
    [self.Details loadHTMLString:[self createHTML:errormsg] baseURL:nil];
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

@end
