//
//  Bonjour.h
//
#import <Foundation/Foundation.h>
#import <PhoneGap/PGPlugin.h>

@interface Bonjour : PGPlugin {
    
    NSString* callbackID;  
    
}

@property (nonatomic, copy) NSString* callbackID;

//Instance Method  

- (void) print:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

- (void)start:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)stop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

- (void) browseServices;

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing;
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser;
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser;
- (void) resolveIPAddress:(NSNetService *)service;

- (void)netServiceDidResolveAddress:(NSNetService *)service;
@end
