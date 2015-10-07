//
//  AppDelegate.m
//  SocketTest
//
//  Created by Derek Carter on 8/26/15.
//
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog(@"didFinishLaunchingWithOptions");
    
    // Register for notifications
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    
    // Create the socket connection
    self.socketConnection = [SocketConnection new];
    
    // Connect to the socket if not connected on app start - This is here in the appDelegate for when the app is in memory on a device startup
    if (!self.socketConnection.connected) {
        NSLog(@"Connecting.......");
        self.socketConnection.host = @"airbornemedia.gogoinflight.com";
        self.socketConnection.port = 9999;
        self.socketConnection.shouldReconnectAutomatically = YES;
        self.socketConnection.reconnectTimeInterval = 3;
        self.socketConnection.timeoutTimeInterval = 2;
        [self.socketConnection connect];
        
        /* DO THIS ONCE BACKGROUNDED
        // Prevent iOS from closing the app
        BOOL backgroundAccepted = [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
            [self backgroundHandler];
        }];
        if (backgroundAccepted) {
            NSLog(@"VOIP backgrounding accepted");
        }
        */
    }
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    self.inBackground = YES;
    
    // Prevent iOS from closing the app
    BOOL backgroundAccepted = [[UIApplication sharedApplication] setKeepAliveTimeout:600 handler:^{
        [self backgroundHandler];
        
        // Consider this handler using "dispatch_block_t"
    }];
    
    if (backgroundAccepted) {
        NSLog(@"VOIP backgrounding accepted");
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
    
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    self.inBackground = NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    NSLog(@"applicationWillTerminate");
}


#pragma mark - Background Execution Methods

- (void)backgroundHandler
{
    NSLog(@"....VOIP backgroundHandler callback");
    
    // Get battery left and status
    UIDevice *myDevice = [UIDevice currentDevice];
    [myDevice setBatteryMonitoringEnabled:YES];
    float batteryLeft = [myDevice batteryLevel]*100;
    NSString *batteryStatus;
    int status = [myDevice batteryState];
    switch (status) {
        case UIDeviceBatteryStateUnplugged:
            batteryStatus = @"Unplugged";
            break;
            
        case UIDeviceBatteryStateCharging:
            batteryStatus = @"Charging";
            break;
            
        case UIDeviceBatteryStateFull:
            batteryStatus = @"Battery Full";
            break;
            
        default:
            batteryStatus = @"Unknown";
            break;
    }
    NSString *statusString = [NSString stringWithFormat:@"Battery Level: %0.0f - Status: %@", batteryLeft, batteryStatus];
    NSLog(@"%@", statusString);
    
    
    // Clear out the old notification before scheduling a new one.
    NSArray *oldNotifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    if ([oldNotifications count] > 0) {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
    
    // Create a new notification
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification) {
        notification.fireDate = [NSDate date];
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.repeatInterval = 0;
        notification.soundName = UILocalNotificationDefaultSoundName; //@"alert.wav";
        notification.alertBody = statusString;
        
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

@end
