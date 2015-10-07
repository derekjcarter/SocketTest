//
//  SocketConnection.h
//  SocketTest
//
//  Created by Derek Carter on 8/26/15.
//
//

#import <Foundation/Foundation.h>

@protocol SocketConnectionDelegate;

@interface SocketConnection : NSObject

@property (nonatomic, assign) id<SocketConnectionDelegate> delegate;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic) BOOL shouldReconnectAutomatically;
@property (nonatomic) NSTimeInterval reconnectTimeInterval;
@property (nonatomic) NSTimeInterval timeoutTimeInterval;
@property (nonatomic, strong) NSString *host;
@property (nonatomic) NSUInteger port;

- (void)sendString:(NSString *)string;
- (void)connect;
- (void)disconnect;

@end


@protocol SocketConnectionDelegate <NSObject>

@optional
- (void)socketConnectionStreamDidConnect:(SocketConnection *)connection;
- (void)socketConnectionStreamDidDisconnect:(SocketConnection *)connection willReconnectAutomatically:(BOOL)willReconnectAutomatically;
- (void)socketConnectionStream:(SocketConnection *)connection didReceiveString:(NSString *)string;
- (void)socketConnectionStream:(SocketConnection *)connection didSendString:(NSString *)string;
- (void)socketConnectionStreamDidFailToConnect:(SocketConnection *)connection willReconnectAutomatically:(BOOL)willReconnectAutomatically;

@end
