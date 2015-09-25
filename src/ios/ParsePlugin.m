#import "AppDelegate.h"
#import "MainViewController.h"

#import "ParsePlugin.h"
#import <Cordova/CDV.h>
#import <Parse/Parse.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <Foundation/Foundation.h>
NSString *msg = @"";

@implementation ParsePlugin

- (void)initialize: (CDVInvokedUrlCommand*)command
{
	@try {
		CDVPluginResult* pluginResult = nil;
		NSString *appId = [command.arguments objectAtIndex:0];
		NSString *clientKey = [command.arguments objectAtIndex:1];
		[Parse setApplicationId:appId clientKey:clientKey];
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	
}

- (void)getInstallationId:(CDVInvokedUrlCommand*) command
{
    @try {
		[self.commandDelegate runInBackground:^{
			CDVPluginResult* pluginResult = nil;
			PFInstallation *currentInstallation = [PFInstallation currentInstallation];
			NSString *installationId = currentInstallation.installationId;
			pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:installationId];
			[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
		}];
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	
}

- (void)getInstallationObjectId:(CDVInvokedUrlCommand*) command
{
	@try {
		[self.commandDelegate runInBackground:^{
			CDVPluginResult* pluginResult = nil;
			PFInstallation *currentInstallation = [PFInstallation currentInstallation];
			NSString *objectId = currentInstallation.objectId;
			pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:objectId];
			[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
		}];
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	
}

- (void)getSubscriptions: (CDVInvokedUrlCommand *)command
{
	@try {
		NSArray *channels = [PFInstallation currentInstallation].channels;
		CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:channels];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}		
}

- (void)subscribe: (CDVInvokedUrlCommand *)command
{

	@try {
		if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
			UIUserNotificationSettings *settings =
			[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert |
														 UIUserNotificationTypeBadge |
														 UIUserNotificationTypeSound
											  categories:nil];
			[[UIApplication sharedApplication] registerUserNotificationSettings:settings];
			[[UIApplication sharedApplication] registerForRemoteNotifications];
		}
		else {
			[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
				UIRemoteNotificationTypeBadge |
				UIRemoteNotificationTypeAlert |
				UIRemoteNotificationTypeSound];
		}
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}		
	@try {
		CDVPluginResult* pluginResult = nil;
		PFInstallation *currentInstallation = [PFInstallation currentInstallation];
		NSString *channel = [command.arguments objectAtIndex:0];
		[currentInstallation addUniqueObject:channel forKey:@"channels"];
		[currentInstallation saveInBackground];
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	
}

- (void)unsubscribe: (CDVInvokedUrlCommand *)command
{
	@try {
		CDVPluginResult* pluginResult = nil;
		PFInstallation *currentInstallation = [PFInstallation currentInstallation];
		NSString *channel = [command.arguments objectAtIndex:0];
		[currentInstallation removeObject:channel forKey:@"channels"];
		[currentInstallation saveInBackground];
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	
}

- (void)getNotificationInfo:(CDVInvokedUrlCommand*) command
{
	@try {
		[self.commandDelegate runInBackground:^{
			CDVPluginResult* pluginResult = nil;
			pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:msg];
			[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
			msg = @"";
		}];
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	
}

@end

@implementation AppDelegate (ParsePlugin)

void MethodSwizzle(Class c, SEL originalSelector) {
	@try {
		NSString *selectorString = NSStringFromSelector(originalSelector);
		SEL newSelector = NSSelectorFromString([@"swizzled_" stringByAppendingString:selectorString]);
		SEL noopSelector = NSSelectorFromString([@"noop_" stringByAppendingString:selectorString]);
		Method originalMethod, newMethod, noop;
		originalMethod = class_getInstanceMethod(c, originalSelector);
		newMethod = class_getInstanceMethod(c, newSelector);
		noop = class_getInstanceMethod(c, noopSelector);
		if (class_addMethod(c, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
			class_replaceMethod(c, newSelector, method_getImplementation(originalMethod) ?: method_getImplementation(noop), method_getTypeEncoding(originalMethod));
		} else {
			method_exchangeImplementations(originalMethod, newMethod);
		}
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	 
}

+ (void)load
{
	@try {
		MethodSwizzle([self class], @selector(application:parseInit:));
		MethodSwizzle([self class], @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:));
		MethodSwizzle([self class], @selector(application:didReceiveRemoteNotification:));
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	 
}

- (void)noop_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
}

- (void)swizzled_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
	@try {
		// Call existing method
		[self swizzled_application:application didRegisterForRemoteNotificationsWithDeviceToken:newDeviceToken];
		// Store the deviceToken in the current installation and save it to Parse.
		PFInstallation *currentInstallation = [PFInstallation currentInstallation];
		[currentInstallation setDeviceTokenFromData:newDeviceToken];
		[[PFInstallation currentInstallation] addUniqueObject:@"" forKey:@"channels"];
		[currentInstallation saveInBackground];
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	 
	
}

- (void)noop_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
}

- (void)swizzled_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
   @try {
		[self swizzled_application:application didReceiveRemoteNotification:userInfo];
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	
}



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  
    
    // Register for Push Notitications
	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	
	[Parse enableLocalDatastore];

	[Parse setApplicationId:@"MXULrSMCXKAtKVv0l2x36yW4r6JcO4nDkSrKlEQu"
				  clientKey:@"u07BoiImZ5FQVtNM2E77F9C8rmPZ18rWWDJjsoVE"];


	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
		@try {
			UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
															UIUserNotificationTypeBadge |
															UIUserNotificationTypeSound);
			UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes	categories:nil];
			[application registerUserNotificationSettings:settings];
			[application registerForRemoteNotifications];			
		}
		@catch (NSException *exception) {
			 NSLog(@"%@", exception.reason);
		}		
    } else
#endif
    {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeAlert |
                                                         UIRemoteNotificationTypeSound)];
    }
	@try {
		UILocalNotification *notification = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if (notification) {
			[self application:application didReceiveRemoteNotification:(NSDictionary*)notification];
		}else{
	  
		}
	}
	@catch (NSException *exception) {
		 NSLog(@"%@", exception.reason);
	}	    
    
#if __has_feature(objc_arc)
    self.window = [[UIWindow alloc] initWithFrame:screenBounds];
#else
    self.window = [[[UIWindow alloc] initWithFrame:screenBounds] autorelease];
#endif
    self.window.autoresizesSubviews = YES;
    
#if __has_feature(objc_arc)
    self.viewController = [[MainViewController alloc] init];
#else
    self.viewController = [[[MainViewController alloc] init] autorelease];
#endif
    
    // Set your app's start page by setting the <content src='foo.html' /> tag in config.xml.
    // If necessary, uncomment the line below to override it.
    //self.viewController.startPage = @"index.html";
    
    // NOTE: To customize the view's frame size (which defaults to full screen), override
    // [self.viewController viewWillAppear:] in your view controller.
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    
    return YES;
}
    

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if ( application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground  )
    {
	
		@try {
			msg = [userInfo objectForKey:@"info"];
			if(!msg){
				msg = @"";
			}
		}
		@catch (NSException *exception) {
			NSLog(@"%@", exception.reason);
			msg = @"";
		}	
		
        /*
        //msg = @"push";
        if ([[userInfo allKeys] containsObject:@"aps"])
        {
            msg = @"aps";
            if([[[userInfo objectForKey:@"aps"] allKeys] containsObject:@"alert"])
            {
                NSDictionary *apsDic = [userInfo valueForKey:@"aps"];
                msg = [apsDic valueForKey:@"alert"];
            }
            
        }
        else{
            //msg = @"push";
        }
         */
    }
    else{
		msg = @"";
    }
    @try {
		[PFPush handlePush:userInfo];
	}
	@catch (NSException *exception) {
		NSLog(@"%@", exception.reason);
	}	
}


@end