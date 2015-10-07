//
//  AppDelegate.h
//  SocketTest
//
//  Created by Derek Carter on 8/26/15.
//
//

#import <UIKit/UIKit.h>
#import "SocketConnection.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) SocketConnection *socketConnection;
@property (nonatomic) BOOL inBackground;

@end
