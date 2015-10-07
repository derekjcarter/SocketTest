//
//  ViewController.m
//  SocketTest
//
//  Created by Derek Carter on 8/26/15.
//
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "SocketConnection.h"

@interface ViewController () <SocketConnectionDelegate>

@property (nonatomic, strong) AppDelegate* appDelegate;
@property (nonatomic, strong) SocketConnection *socketConnection;
@property (nonatomic, weak) IBOutlet UITextField *hostTextField;
@property (nonatomic, weak) IBOutlet UITextField *portTextField;
@property (nonatomic, weak) IBOutlet UITextView *debugTextView;
@property (nonatomic, weak) IBOutlet UIButton *connectButton;
@property (nonatomic, weak) IBOutlet UITextField *textField; // Used to sending data to server (server is not ready for this yet)

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.socketConnection = [SocketConnection new];
    //self.socketConnection.delegate = self;
    
    self.appDelegate = [UIApplication sharedApplication].delegate;
    self.socketConnection = self.appDelegate.socketConnection;
    self.socketConnection.delegate = self;
    
    self.hostTextField.text = @"airbornemedia.gogoinflight.com";
    self.portTextField.text = @"9999";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Action Methods

- (IBAction)connect:(id)sender
{
    if (!self.socketConnection.connected) {
        NSUInteger port = [self.portTextField.text integerValue];
        
        [self debugString:[NSString stringWithFormat:@"Connecting to host %@:%@", self.hostTextField.text, @(port)]];
        
        self.socketConnection.host = self.hostTextField.text;
        self.socketConnection.port = port;
        self.socketConnection.shouldReconnectAutomatically = YES;
        self.socketConnection.reconnectTimeInterval = 3;
        self.socketConnection.timeoutTimeInterval = 2;
        [self.socketConnection connect];
    } else {
        [self.socketConnection disconnect];
        [self updateConnectButton];
        [self debugString:@"Disconnected"];
    }
}

- (IBAction)send:(id)sender
{
    [self.socketConnection sendString:self.textField.text];
}


#pragma mark - SocketConnectionDelegate Methods

- (void)socketConnectionStreamDidConnect:(SocketConnection *)connection
{
    [self debugString:@"Connected"];
    [self updateConnectButton];
}

- (void)socketConnectionStreamDidDisconnect:(SocketConnection *)connection willReconnectAutomatically:(BOOL)willReconnectAutomatically
{
    [self debugString:@"Disconnected"];
    [self updateConnectButton];
}

- (void)socketConnectionStream:(SocketConnection *)connection didReceiveString:(NSString *)string
{
    [self debugString:[NSString stringWithFormat:@"Received: %@", string]];
    
    if (self.appDelegate.inBackground) {
        // Update badge number
        NSInteger badgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber;
        [UIApplication sharedApplication].applicationIconBadgeNumber = badgeNumber + 1;
        
        // Notification of string
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        if (notification) {
            notification.fireDate = [NSDate date];
            notification.timeZone = [NSTimeZone defaultTimeZone];
            notification.repeatInterval = 0;
            notification.soundName = UILocalNotificationDefaultSoundName; //@"alert.wav";
            notification.alertTitle = @"New Message";
            notification.alertAction = @"View";
            notification.alertBody = string;
            
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        }
    }
}

- (void)socketConnectionStream:(SocketConnection *)connection didSendString:(NSString *)string
{
    [self debugString:[NSString stringWithFormat:@"Sent: %@", string]];
}

- (void)socketConnectionStreamDidFailToConnect:(SocketConnection *)connection
{
    [self debugString:[NSString stringWithFormat:@"Could not connect to %@", self.socketConnection.host]];
}


#pragma mark - Helper Methods

- (void)updateConnectButton
{
    [self.connectButton setTitle:self.socketConnection.connected ? @"Disconnect" : @"Connect" forState:UIControlStateNormal];
}

- (void)debugString:(NSString *)string
{
    self.debugTextView.text = [self.debugTextView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n", string]];
}

@end
