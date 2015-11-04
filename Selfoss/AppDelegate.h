//
//  AppDelegate.h
//  Selfoss
//
//  Created by Dimitri on 01/10/13.
//  Copyright (c) 2015 Graphic-identité. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface AppDelegate : NSObject <NSApplicationDelegate,NSURLDownloadDelegate,WKUIDelegate,NSUserNotificationCenterDelegate,WebUIDelegate,WebPolicyDelegate,WebFrameLoadDelegate>
{
    
    IBOutlet NSMenuItem *AboutSelfoss;
    IBOutlet NSMenuItem *MenuPreferences;
    IBOutlet NSMenuItem *MenuCopy;
    IBOutlet NSMenuItem *MenuPaste;
    IBOutlet NSMenuItem *MenuFullscreen;
    IBOutlet NSMenuItem *MenuReload;
    IBOutlet NSMenuItem *MenuHide;
    IBOutlet NSMenuItem *MenuQuit;
    
    
    IBOutlet NSButton *butPref;
    IBOutlet NSButton *butHide;
    IBOutlet NSButton *butMark;
    IBOutlet NSButton *butStar;
    IBOutlet NSButton *butAll;
    IBOutlet NSButton *butNew;
    
    IBOutlet NSPanel *loginPanel;
    IBOutlet NSSecureTextField *pass;
    IBOutlet NSTextField *user;
    IBOutlet NSButton *Donation;
    IBOutlet NSComboBox *catFluxBox;
    IBOutlet NSComboBox *catFluxBox2;
    IBOutlet NSComboBox *catFluxBox3;
    IBOutlet NSTextField *selfossUrlField;

    IBOutlet NSPanel *prefPanel;

    IBOutlet NSButton *menuCheckUpdates;
    IBOutlet NSButton *checkdefault;
    IBOutlet NSButton *menuHiddenPref;
    IBOutlet NSButton *menuReloadPref;
    IBOutlet NSButton *menuAnim;
    IBOutlet NSButton *menuNotify;
    IBOutlet NSButton *menuFullscreen;
    IBOutlet NSTextField *selfossURLtext;
    IBOutlet NSTextField *badgeCounter;
    IBOutlet NSButton *ValidatePref;
    IBOutlet NSButton *github;
    
    IBOutlet NSTextField *feedTitleText;
    IBOutlet NSTextField *categoriesText;
    IBOutlet NSButton *CancelText;
    IBOutlet NSButton *AddText;
    
    IBOutlet NSTextField *FeedLogin;
    IBOutlet NSTextField *FeedPassword;
    
    CFStringRef feedScheme;
    CFStringRef bundleID;
    NSUserDefaults *defaults;
    int activetime;
    int unactivetime;
    
    IBOutlet NSSlider *slideTimeActive;
    IBOutlet NSSlider *slideTimeUnactive;
    
    IBOutlet NSTextField *textTimeActive;
    IBOutlet NSTextField *textTimeUnactive;

    NSString *hidemenu;
    BOOL feedError;
    
    IBOutlet NSWindow *addFluxWindow;
    IBOutlet NSTextField *titreFlux;
    IBOutlet NSTextField *catFlux;
    IBOutlet NSTextField *urlFlux;
    IBOutlet id selfossView;
    IBOutlet id selfossWindow;
    
    
    NSMutableSet *otherWebViews;
    NSTimer *timer;

    NSTimer *animTimer;
        NSString *urlStr;
    
    NSString *tileNumber;
    
    BOOL firstLaunch;
    
}









@end
