//
//  AppDelegate.m
//  VsMobile_FullWeb
//
//  Created by admin on 8/8/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "AppDelegate.h"

NSData *APPLICATION_FILE;
NSData *FEED_FILE;
NSString *APPLICATION_SUPPORT_PATH;

// INFO : not manually throw exception here => cannot display alert view before shut down the application. More user friendly.

@implementation AppDelegate

+ (BOOL) testConnection
{
    // Set the host
    Reachability *checkConnection = [Reachability reachabilityWithHostName:@"10.1.40.37"];
    NetworkStatus networkStatus = [checkConnection currentReachabilityStatus];
    NSLog(@"Network Status : %d", networkStatus);
    
    BOOL isConnected = false;
    switch (networkStatus) {
        case NotReachable:
            isConnected = false;
            break;
        case ReachableViaWiFi:
            isConnected = true;
            break;
        case ReachableViaWWAN:
            isConnected = [self testFastConnection];
            break;
        default:
            break;
    }
    
    return isConnected;
}

+ (BOOL) testFastConnection
{
    BOOL isFast = false;
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    
    if ([info.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge] ||
        [info.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyWCDMA]) {
        isFast = false;
    }
    else {
        isFast = true;
    }
    
    return isFast;
}

// INFO : ExtensionType is necessary when fileName does not contain an extension (i.e. js, css, json, ...)
- (void) saveFile:(NSString *)url fileName:(NSString *)fileName extensionType:(NSString *)extensionType dirName:(NSString*)dirName
{
    @try {
        url = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        fileName = [fileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        extensionType = [extensionType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        BOOL success = false;
        //NSString *path = [NSString stringWithFormat:@"%@%@.%@", APPLICATION_SUPPORT_PATH, fileName, [AppDelegate extensionType:extensionType]];
        NSString *path = [NSString stringWithFormat:@"%@%@", APPLICATION_SUPPORT_PATH, fileName];
        
        // Create Template's page directory when dependency is for a page
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = [[NSError alloc] init];
        if (![dirName isKindOfClass:[NSNull class]]) {
            dirName = [dirName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            BOOL isDirectory;
            path = [NSString stringWithFormat:@"%@%@/%@", APPLICATION_SUPPORT_PATH, dirName, fileName];
            if (![fileManager fileExistsAtPath:[NSString stringWithFormat:@"%@%@", APPLICATION_SUPPORT_PATH, dirName] isDirectory:&isDirectory]) {
                success = [fileManager createDirectoryAtPath:[NSString stringWithFormat:@"%@%@", APPLICATION_SUPPORT_PATH, dirName] withIntermediateDirectories:YES attributes:nil error:&error];
                if (!success) {
                    NSLog(@"An error occured during the Creation of Template folder : %@", error);
                }
            }
        }
        //if ([AppDelegate extensionType:extensionType]) {
        NSURL *location = [NSURL URLWithString:url];
        if (![fileManager fileExistsAtPath:path]) {
            success =[[NSData dataWithContentsOfURL:location] writeToFile:path options:NSDataWritingAtomic error:&error];
            if (!success) {
                NSLog(@"An error occured during the Saving of the file %@ : %@", fileName, error);
            }
        }
        //}
        //else {
        //NSLog(@"An error occured during the Saving of the file %@ : the extension %@ is not supported yet !", fileName, extensionType);
        //}
    }
    @catch (NSException *e) {
        NSLog(@"An error occured during the Loading of the file %@ : %@, reason : %@", fileName, e.name, e.reason);
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];
        // Wait while app is going background
        [NSThread sleepForTimeInterval:2.0];
        exit(0);
    }
}

- (void) searchDependencies
{
    if (![[self.application objectForKey:@"Dependencies"] isKindOfClass:[NSNull class]]) {
        if ([self.application objectForKey:@"Dependencies"]) {
            for (NSMutableDictionary *allAppDep in [self.application objectForKey:@"Dependencies"]) {
                if ([allAppDep objectForKey:@"Url"] && [allAppDep objectForKey:@"Name"] /*&& [allAppDep objectForKey:@"Type"]*/) {
                    if ([allAppDep objectForKey:@"Path"]) {
                        [self saveFile:[allAppDep objectForKey:@"Url"] fileName:[allAppDep objectForKey:@"Name"] extensionType:[allAppDep objectForKey:@"Type"] dirName:[allAppDep objectForKey:@"Path"]];
                    }
                    else {
                        [self saveFile:[allAppDep objectForKey:@"Url"] fileName:[allAppDep objectForKey:@"Name"] extensionType:[allAppDep objectForKey:@"Type"] dirName:nil];
                    }
                }
                else {
                    NSLog(@"An error occured during the Search of Application's dependencies. For %@ : one or more parameters are null !", [allAppDep objectForKey:@"Name"]);
                }
            }
            // INFO : ExtensionType is necessary when fileName does not contain an extension (i.e. js, css, json, ...). That's why it is commented
            for (NSMutableDictionary *allPages in [self.application objectForKey:@"Pages"]) {
                for (NSMutableDictionary *allPageDep in [allPages objectForKey:@"Dependencies"]) {
                    if (![[allPageDep objectForKey:@"Url"] isKindOfClass:[NSNull class]] && ![[allPageDep objectForKey:@"Name"] isKindOfClass:[NSNull class]] /*&& [allPageDep objectForKey:@"Type"]*/) {
                        if (![[allPageDep objectForKey:@"Path"]  isKindOfClass:[NSNull class]]) {
                            [self saveFile:[allPageDep objectForKey:@"Url"] fileName:[allPageDep objectForKey:@"Name"] extensionType:[allPageDep objectForKey:@"Type"] dirName:[allPageDep objectForKey:@"Path"]];
                        }
                        else {
                            [self saveFile:[allPageDep objectForKey:@"Url"] fileName:[allPageDep objectForKey:@"Name"] extensionType:[allPageDep objectForKey:@"Type"] dirName:nil];
                        }
                    }
                    else {
                        NSLog(@"An error occured during the Search of %@'s dependencies : one or more parameters are null !", [allPages objectForKey:@"Name"]);
                    }
                }
            }
        }
    }
}

+ (NSString *) extensionType:(NSString *)type
{
    NSString *extension;
    type = [type stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [type lowercaseString];
    if ([type isEqualToString:@"script"]) {
        extension = @"js";
    }
    else if ([type isEqualToString:@"style"]) {
        extension = @"css";
    }
    else {
        extension = nil;
    }
    return extension;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
    }
    
#pragma Create the Application Support Folder. Not accessible by users
    // NSHomeDirectory returns the application's sandbox directory. Application Support folder will contain all files that we need for the application
    APPLICATION_SUPPORT_PATH = [NSString stringWithFormat:@"%@/Library/Application Support/", NSHomeDirectory()];
    NSLog(@"APPLICATION_SUPPORT_PATH = %@", APPLICATION_SUPPORT_PATH);
    
    // Application Support folder is not always created by default. The following code creates it.
    // Get the Bundle identifier for creating dynamic path for storing all files
    NSString *bundle = [[NSBundle mainBundle] bundleIdentifier];
    // FileManager is using for creating the Application Support Folder
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = [[NSError alloc] init];
    NSURL *appliSupportDir = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (appliSupportDir) {
        [appliSupportDir URLByAppendingPathComponent:bundle isDirectory:YES];
    }
    else {
        NSLog(@"An error occured during the Creation of Application Support folder : %@", error);
    }
    
    bundle = [[NSBundle mainBundle] pathForResource:@"Configuration" ofType:@"plist"];
    NSDictionary *config = [[NSDictionary alloc] initWithContentsOfFile:bundle];
    
#pragma Download & save Json Files
    // Read Json file in network
    @try {
        BOOL success = false;
        // Get Application File
        // Get config file
        NSString *webApi = [NSString stringWithFormat:@"%@%@", [config objectForKey:@"WebAPI"], [config objectForKey:@"ApplicationID"]];
        NSURL *url = [NSURL URLWithString:webApi];
        
        NSString *path = [NSString stringWithFormat:@"%@%@.json", APPLICATION_SUPPORT_PATH, [config objectForKey:@"ApplicationID"]];
        if (![fileManager fileExistsAtPath:path]) {
            NSLog(@"File does not exist");
            // Check Connection
            success = [AppDelegate testConnection];
            if (success) {
                NSLog(@"Connection is OK");
                APPLICATION_FILE = [NSData dataWithContentsOfURL:url];
                success =[[NSData dataWithContentsOfURL:url] writeToFile:path options:NSDataWritingAtomic error:&error];
                if (success) {
                    _isDownloadedByNetwork = true;
                }
                else {
                    NSLog(@"An error occured during the Saving of Application File : %@", error);
                }
            }
        }
        else {
            NSLog(@"File exists");
            APPLICATION_FILE = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&error];
            if (APPLICATION_FILE) {
                _isDownloadedByFile = true;
            }
            else {
                NSLog(@"An error occured during the Loading of Application File : %@", error);
            }
        }
        if (APPLICATION_FILE) {
            self.application = (NSMutableDictionary *)[NSJSONSerialization JSONObjectWithData:APPLICATION_FILE options:NSJSONReadingMutableLeaves error:&error];
            if (self.application) {
                [self searchDependencies];
            }
            else {
                NSLog(@"An error occured during the Deserialization of Application file : %@", error);
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"An error occured during the Saving of a Json file : %@, reason : %@", exception.name, exception.reason);
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];
        // Wait while app is going background
        [NSThread sleepForTimeInterval:2.0];
        exit(0);
    }
    NSLog(@"Dl by Network : %hhd", _isDownloadedByNetwork);
    NSLog(@"Dl by File : %hhd", _isDownloadedByFile);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
