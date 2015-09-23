#import <Cordova/CDV.h>
#import "AppDelegate.h"

@interface ParsePlugin: CDVPlugin
- (void)initialize: (CDVInvokedUrlCommand*)command;
- (void)getInstallationId: (CDVInvokedUrlCommand*)command;
- (void)getInstallationObjectId: (CDVInvokedUrlCommand*)command;
- (void)getSubscriptions: (CDVInvokedUrlCommand *)command;
- (void)subscribe: (CDVInvokedUrlCommand *)command;
- (void)unsubscribe: (CDVInvokedUrlCommand *)command;
- (void)getNotificationInfo: (CDVInvokedUrlCommand*)command;
@end

@interface AppDelegate (ParsePlugin)
@end
