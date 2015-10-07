//
//  SocketConnection.m
//  SocketTest
//
//  Created by Derek Carter on 8/26/15.
//
//

#import "SocketConnection.h"
#import "AppDelegate.h"


static BOOL kShouldReconnectAutomatically = YES;
static NSTimeInterval kReconnectTimeInterval = 3;
static NSTimeInterval kTimeoutTimeInterval = 5;


@interface SocketConnection () <NSStreamDelegate>

@property (nonatomic) CFSocketRef socket;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic) BOOL connected;

@end


@implementation SocketConnection

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.shouldReconnectAutomatically = kShouldReconnectAutomatically;
        self.reconnectTimeInterval = kReconnectTimeInterval;
        self.timeoutTimeInterval = kTimeoutTimeInterval;
    }
    return self;
}


#pragma mark - Connection Methods

- (void)connect
{
    NSLog(@"connect to %@:%@", self.host, @(self.port));
    
    [self disconnect];
    
    // Create input and output streams
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    // Connect socket to host/port
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)(self.host), (UInt32)self.port, &readStream, &writeStream);
    
    // Set VoIP properties on streams
    CFReadStreamSetProperty(readStream, kCFStreamNetworkServiceType, kCFStreamNetworkServiceTypeVoIP);
    CFWriteStreamSetProperty(writeStream, kCFStreamNetworkServiceType, kCFStreamNetworkServiceTypeVoIP);
    
    // Bridge old school CFStreams to NSStreams for delegates
    self.inputStream = (__bridge NSInputStream *)readStream;
    self.outputStream = (__bridge NSOutputStream *)writeStream;
    
    // Make sure VoIP properties on streams (could be redundant)
    [self.inputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    [self.outputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    
    // Set delegate on input and output streams
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    
    // Run the stream loop
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    // Open connections
    [self.inputStream open];
    [self.outputStream open];
    
    // Set timeout and interval
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
    [self performSelector:@selector(timeout) withObject:nil afterDelay:self.timeoutTimeInterval];
}

- (void)disconnect
{
    if (nil == self.inputStream && nil == self.outputStream) {
        return;
    }
    NSLog(@"disconnect");

    // Close streams
    [self.inputStream close];
    [self.outputStream close];

    // Remove streams from run loop
    [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    // Dealloc streams
    self.inputStream = nil;
    self.outputStream = nil;
    self.connected = NO;
}

- (void)timeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
    [self connectFailure];
}

- (void)reconnectAutomatically
{
    NSLog(@"Will reconnect automatically in %@s", @(self.reconnectTimeInterval));
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connect) object:nil];
    [self performSelector:@selector(connect) withObject:nil afterDelay:self.reconnectTimeInterval];
}

- (void)setShouldReconnectAutomatically:(BOOL)shouldReconnectAutomatically
{
    _shouldReconnectAutomatically = shouldReconnectAutomatically;
    
    // Connect if set true
    if (!_shouldReconnectAutomatically) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connect) object:nil];
    }
}

- (void)connectSuccess:(NSStream *)theStream
{
    NSLog(@"connectSuccess: Stream opened");
    
    if (theStream == self.outputStream) {
        // Cancel timeout call
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
        
        self.connected = YES;
        
        // Call delegate after successful connection
        if ([self.delegate respondsToSelector:@selector(socketConnectionStreamDidConnect:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate socketConnectionStreamDidConnect:self];
            });
        }
    }
}

- (void)connectFailure
{
    NSLog(@"Can not connect to the host!");
    
    // Confirm disconnection
    [self disconnect];
    
    // Call delegate after failure
    if ([self.delegate respondsToSelector:@selector(socketConnectionStreamDidFailToConnect:willReconnectAutomatically:)]) {
        [self.delegate socketConnectionStreamDidFailToConnect:self willReconnectAutomatically:self.shouldReconnectAutomatically];
    }
    
    // Retry if set
    if (self.shouldReconnectAutomatically) {
        [self reconnectAutomatically];
    }
}


#pragma mark - Send Methods

- (void)sendString:(NSString *)string
{
    NSLog(@"sendString:%@", string);
    
    // Send string as bytes
    NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding];
    [self.outputStream write:[data bytes] maxLength:[data length]];
    
    // Call delegate after send string
    if ([self.delegate respondsToSelector:@selector(socketConnectionStream:didSendString:)]) {
        [self.delegate socketConnectionStream:self didSendString:string];
    }
}


#pragma mark - NSStreamDelegate Methods

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    //NSLog(@"NSStreamDelegate Stream Event: %@", @(streamEvent));
    
    switch (streamEvent) {
        case NSStreamEventNone:
            NSLog(@"NSStreamEventNone");
            break;

        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            [self connectSuccess:theStream];
            break;

        case NSStreamEventHasBytesAvailable:
            NSLog(@"NSStreamEventOpenCompleted");
            if (theStream == self.inputStream) {

                uint8_t buffer[1024];
                NSInteger len;

                while ([self.inputStream hasBytesAvailable]) {
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        if (nil != output) {
                            NSLog(@"Server Output: %@", output);
                            if ([self.delegate respondsToSelector:@selector(socketConnectionStream:didReceiveString:)]) {
                                [self.delegate socketConnectionStream:self didReceiveString:output];
                            }
                        }
                    }
                }
            }
            break;

        case NSStreamEventHasSpaceAvailable:
            NSLog(@"NSStreamEventHasSpaceAvailable");
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"NSStreamEventErrorOccurred: %@", theStream.streamError);
            [self connectFailure];
            break;

        case NSStreamEventEndEncountered:
            NSLog(@"NSStreamEventEndEncountered");
            [self disconnect];
            if ([self.delegate respondsToSelector:@selector(socketConnectionStreamDidDisconnect:willReconnectAutomatically:)]) {
                [self.delegate socketConnectionStreamDidDisconnect:self willReconnectAutomatically:self.shouldReconnectAutomatically];
            }
            if (self.shouldReconnectAutomatically) {
                [self reconnectAutomatically];
            }
            break;

        default:
            NSLog(@"Unknown NSStreamEvent");
    }
}


@end
