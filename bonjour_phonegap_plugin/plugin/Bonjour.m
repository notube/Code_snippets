//
//  Bonjour.m
//  


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <arpa/inet.h>

#import "Bonjour.h" 


#define kWebServiceType @"_http._tcp"
#define xbmcWebServiceType @"_xbmc-jsonrpc._tcp"
//#define xbmcWebServiceType @"_http._tcp"


#define kInitialDomain  @"local"

@implementation Bonjour 

@synthesize callbackID;


-(void)print:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options  
{
    
    //The first argument in the arguments parameter is the callbackID.
    //We use this to send data back to the successCallback or failureCallback
    //through PluginResult.   
    self.callbackID = [arguments pop];
    NSLog(self.callbackID);
    
    //Get the string that javascript sent us 
    NSString *stringObtainedFromJavascript = [arguments objectAtIndex:0]; 
    NSLog(stringObtainedFromJavascript);
    [self browseServices];
   
}

- (void)start:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
}

- (void)stop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
}


NSMutableArray *services;
NSNetServiceBrowser *browser;

- (void) browseServices {
    NSLog(@"aaa");
    services = [NSMutableArray new];
    browser = [[NSNetServiceBrowser new] autorelease];
    browser.delegate = self;

    [browser searchForServicesOfType:xbmcWebServiceType inDomain:@""];

 // [browser searchForServicesOfType:@"_http._tcp" inDomain:@""];
    NSLog(@"aaa14");
    
}

- (void) triggerSend:(NSString *) str{
    NSLog(@"trigger");
    NSLog(str);
    //[NSThread sleepForTimeInterval:1];
    PluginResult* result;
    //NSNumber numberWithBool:YES
    result = [PluginResult resultWithStatus:PGCommandStatus_OK
                            messageAsString:str];
    result.keepCallback = [NSNumber numberWithBool: YES];
    [self writeJavascript: [result toSuccessCallbackString:callbackID]];
    
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing{}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser 
           didFindService:(NSNetService *)aService moreComing:(BOOL)more {
    
    [services addObject:aService];
    NSLog(@"Found service. Resolving address...\n");

    [self resolveIPAddress:aService];
    
}

-(void) resolveIPAddress:(NSNetService *)service {    
    NSNetService *remoteService = service;
    remoteService.delegate = self;
    [remoteService resolveWithTimeout:0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo{
    NSLog(@"oops[1]");
    
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing{}
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing{}
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser{}
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser{}
- (void)netServiceDidResolveAddress:(NSNetService *)service {

    NSLog(@"called");
    NSData *foo = [service TXTRecordData];
    NSLog(@"foo %@",foo);   
    
    for (NSData* data in [service addresses]) {
        NSString           *name = nil;

        int                port;
        NSString           *type = nil;
        
     
        char addressBuffer[100];
        struct sockaddr_in* socketAddress = (struct sockaddr_in*) [data bytes];
        name = [service name];
        type = [service type];
        NSLog(@"domain %@",[service domain]);

        int sockFamily = socketAddress->sin_family;
        //serv_addr.sun_path
        if (sockFamily == AF_INET) {

 //       if (sockFamily == AF_INET || sockFamily == AF_INET6) {
            
            const char* addressStr = inet_ntop(sockFamily,
                                               &(socketAddress->sin_addr), addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sin_port);
            
            if (addressStr && port){
                NSLog(@"Found service at %s:%d ", addressStr, port);
                NSLog(type);
                
                NSString *str = [[NSString alloc] initWithFormat:@"%s|%d|%@",addressStr,port,name];
                //NSLog(str);
                [self triggerSend:str];

            }
    
        }
    }
    
    
}


@end
