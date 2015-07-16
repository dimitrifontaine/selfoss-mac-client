//
//  AppDelegate.m
//  Selfoss
//
//  Created by Dimitri on 01/10/13.
//  Copyright (c) 2015 Graphic-identité. All rights reserved.
//

#import "AppDelegate.h"
static int currentFrame;

@implementation AppDelegate

#define selfossURL @"http://selfoss.aditu.de/"
#define selfossActive @"5"
#define selfossUnactive @"15"
#define selfossHide @"yes"
#define selfossReload @"reloadno"
#define selfossFullScreen @"fullno"
#define selfossCheck @"checkyes"
#define selfossNotify @"notifyyes"
#define selfossAnim @"animyes"
#define selfossCheck @"checkyes"


- (id)init {
    
    defaults = [NSUserDefaults standardUserDefaults];
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    if ((self = [super init])) {
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(appDidActivate:)
                                                                   name:NSWorkspaceDidActivateApplicationNotification
                                                                 object:nil];
    }
    
    return self;
}



-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    firstLaunch = '\0';

    [self launchAnim];
    
    if ([defaults stringForKey:selfossActive] == nil)[defaults setObject:selfossActive forKey:selfossActive];
    if ([defaults stringForKey:selfossUnactive] == nil)[defaults setObject:selfossUnactive forKey:selfossUnactive];
    if ([defaults stringForKey:selfossHide] == nil)[defaults setObject:selfossHide forKey:selfossHide];
    if ([defaults stringForKey:selfossReload] == nil)[defaults setObject:selfossReload forKey:selfossReload];
    if ([defaults stringForKey:selfossFullScreen] == nil)[defaults setObject:selfossFullScreen forKey:selfossFullScreen];
    if ([defaults stringForKey:selfossNotify] == nil)[defaults setObject:selfossNotify forKey:selfossNotify];
    if ([defaults stringForKey:selfossAnim] == nil)[defaults setObject:selfossAnim forKey:selfossAnim];
        if ([defaults stringForKey:selfossCheck] == nil)[defaults setObject:selfossCheck forKey:selfossCheck];
    
    if ([defaults stringForKey:selfossURL] == nil){
        [defaults setObject:selfossURL forKey:selfossURL];
        firstLaunch = '\1';
    }
    
    
    
    [self localize];

    
    
    feedScheme = (__bridge CFStringRef)@"feed";
    NSString *defaultRSSClientString = ( NSString *)LSCopyDefaultHandlerForURLScheme(feedScheme);
    bundleID = (__bridge CFStringRef)[[NSBundle mainBundle] bundleIdentifier];
    NSString *selfossID = [(__bridge NSString *)bundleID lowercaseString];
    [checkdefault setEnabled: YES];
    [checkdefault setState:NSOffState];
    
    if ([selfossID isEqualToString:defaultRSSClientString]) {
        [checkdefault setEnabled: NO];
        [checkdefault setState:NSOnState];
    }
    
    [self validTimerPref];
    
    [slideTimeActive setTarget:self];
    [slideTimeActive setAction:@selector(valueChanged:)];
    [slideTimeUnactive setTarget:self];
    [slideTimeUnactive setAction:@selector(valueChanged:)];
    
    hidemenu=@"1";
    if ([[defaults stringForKey:selfossHide] isEqualToString:@"yes"])
    {
        [menuHiddenPref setState:NSOnState];
        [self hideMenu2];
    }
    else
    {
        [menuHiddenPref setState:NSOffState];
        
    }
    
    if ([[defaults stringForKey:selfossReload] isEqualToString:@"reloadyes"])
    {
        [menuReloadPref setState:NSOnState];
    }
    else
    {
        [menuReloadPref setState:NSOffState];
    }
    
    [selfossUrlField setStringValue:[defaults stringForKey:selfossURL]];
    
    

    
    
    if ([[defaults stringForKey:selfossFullScreen] isEqualToString:@"fullyes"])
    {
        [menuFullscreen setState:NSOnState];
        [selfossWindow toggleFullScreen:nil];
    }
    else
    {
        [menuFullscreen setState:NSOffState];
    }
    
    
    if ([[defaults stringForKey:selfossNotify] isEqualToString:@"notifyyes"])
    {
        [menuNotify setState:NSOnState];
    }
    else
    {
        [menuNotify setState:NSOffState];
    }
    
    
    if ([[defaults stringForKey:selfossAnim] isEqualToString:@"animyes"])
    {
        [menuAnim setState:NSOnState];
    }
    else
    {
        [menuAnim setState:NSOffState];
    }
    
    if ([[defaults stringForKey:selfossCheck] isEqualToString:@"checkyes"])
    {
        [menuCheckUpdates setState:NSOnState];
        [self checkUpdate];
    }
    else
    {
        [menuCheckUpdates setState:NSOffState];
    }
    
    
    
    [selfossWindow setReleasedWhenClosed:NO];
    [selfossView setUIDelegate:self];
    
    [[selfossView preferences] setJavaScriptEnabled:YES];
    [[selfossView preferences] setJavaScriptCanOpenWindowsAutomatically:YES];
    
    //   [selfossView setShouldUpdateWhileOffscreen:YES];
 /*   [[selfossView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[defaults stringForKey:selfossURL]]]];
    
    
    if (firstLaunch)  {  [NSApp beginSheet:prefPanel
                            modalForWindow:(NSWindow *)selfossWindow
                             modalDelegate:self
                            didEndSelector:nil
                               contextInfo:nil];
    }
    [self reloadtimer];*/
    // [self redirectConsoleLogToDocumentFolder];
    
    [self connectServer];

}


- (void)connectServer{
    if ([self hasInternet] == YES)
    {
        NSLog(@"internet OK");
        [[selfossView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[defaults stringForKey:selfossURL]]]];
        
        
        if (firstLaunch)  {  [NSApp beginSheet:prefPanel
                                modalForWindow:(NSWindow *)selfossWindow
                                 modalDelegate:self
                                didEndSelector:nil
                                   contextInfo:nil];
        }
        [self reloadtimer];

    }
    else
    {
        NSLog(@"NO internet");
        usleep(1000000);
        [self connectServer];
        
    }
}

- (bool)hasInternet {
    NSURL *url = [[NSURL alloc] initWithString:selfossURL];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:5.0];
    BOOL connectedToInternet = NO;
    if ([NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil]) {
        connectedToInternet = YES;
    }
    //if (connectedToInternet)
    //NSLog(@"We Have Internet!");
    [request release];
    [url release];
    return connectedToInternet;
}


- (BOOL)checkUpdate {
    /* first check for new version (will be nil if no active internet connection) */
    
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://raw.githubusercontent.com/dimitrifontaine/selfoss-mac-client/master/version.txt"]];
    NSData *data = [NSData dataWithContentsOfURL:URL];
    NSString *latestVersionString = [NSString stringWithUTF8String:[data bytes]];
    NSString *actualVerion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSLog(@"version server %@",latestVersionString);
    NSLog(@"version installée %@",actualVerion);
    if (![latestVersionString isEqualToString:actualVerion]) {
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Download"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Check for Updates…"];
        [alert setInformativeText:@"An update is available,\rdo you want to download it?"];
        [alert setAlertStyle:NSWarningAlertStyle];
        if ([alert runModal] == NSAlertFirstButtonReturn)
        {
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/dimitrifontaine/selfoss-mac-client/blob/master/Selfoss.zip"]];
            NSLog(@"Download");
            [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
        }
        [alert release];
        return NO;
    }
    else
    {
        return YES;
    }
    
}

- (IBAction)checkUpdate2:(id)sender {
    if ([self checkUpdate])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Check for Updates…"];
        [alert setInformativeText:@"you already have the latest version"];
        [alert runModal];
    }
}




- (void) redirectConsoleLogToDocumentFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"selfoss.log"];
    freopen([logPath fileSystemRepresentation],"a+",stderr);
}


-(void) localize
{
    NSString *actualVerion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    [github setTitle:    [NSString stringWithFormat:@"Version : %@ - %@", actualVerion, NSLocalizedString(@"(go to github project page)", @"(go to github project page)")]];
    
    
    [checkdefault setTitle: NSLocalizedString(@"Default RSS app", @"Default RSS app")];
    [menuHiddenPref setTitle: NSLocalizedString(@"Hide menu at startup", @"Hide menu at startup")];
    [menuReloadPref setTitle: NSLocalizedString(@"Auto-reload", @"Auto-reload")];
    [menuAnim setTitle: NSLocalizedString(@"Animated dock icon", @"Animated dock icon")];
    [menuNotify setTitle: NSLocalizedString(@"Notifications", @"Notifications")];
    [menuFullscreen setTitle: NSLocalizedString(@"Fullscreen at startup", @"Fullscreen at startup")];
        [menuCheckUpdates setTitle: NSLocalizedString(@"Check for updates at startup", @"Check for updates at startup")];
    [ValidatePref setTitle: NSLocalizedString(@"Validate", @"Validate")];
    [badgeCounter setStringValue: NSLocalizedString(@"badge counter refresh time interval", @"badge counter refresh time interval")];
    [selfossURLtext setStringValue: NSLocalizedString(@"My Selfoss URL", @"My Selfoss URL")];
    
    [feedTitleText setStringValue: NSLocalizedString(@"Feed title", @"Feed title")];
    [categoriesText setStringValue: NSLocalizedString(@"Categories (up to 3, write or select in list)", @"Categories (up to 3, write or select in list)")];
    [CancelText setTitle: NSLocalizedString(@"Cancel", @"Cancel")];
    [AddText setTitle: NSLocalizedString(@"Add", @"Add")];
    
    
    [FeedLogin setStringValue: NSLocalizedString(@"Login", @"Login")];
    [FeedPassword setStringValue: NSLocalizedString(@"Password", @"Password")];
    
    [butPref setToolTip: NSLocalizedString(@"Preferences", @"Preferences")];
    [butHide setToolTip: NSLocalizedString(@"Hide menu", @"Hide menu")];
    [butMark setToolTip: NSLocalizedString(@"Mark all as read", @"Mark all as read")];
    [butStar setToolTip: NSLocalizedString(@"Stared", @"Stared")];
    [butAll setToolTip: NSLocalizedString(@"All items", @"All items")];
    [butNew setToolTip: NSLocalizedString(@"Unread", @"Unread")];
    
    
    [AboutSelfoss setTitle: NSLocalizedString(@"About Selfoss",@"About Selfoss")];
    [MenuPreferences setTitle: NSLocalizedString(@"Preferences",@"Preferences")];
    [MenuCopy setTitle: NSLocalizedString(@"Copy",@"Copy")];
    [MenuPaste setTitle: NSLocalizedString(@"Paste",@"Paste")];
    [MenuFullscreen setTitle: NSLocalizedString(@"Fullscreen",@"Fullscreen")];
    [MenuReload setTitle: NSLocalizedString(@"Reload Selfoss",@"Reload Selfoss")];
    [MenuHide setTitle: NSLocalizedString(@"Hide Selfoss",@"Hide Selfoss")];
    [MenuQuit setTitle: NSLocalizedString(@"Quit Selfoss",@"Quit Selfoss")];

    
    
}









// HANDLE FEED + ADD SUBSCRIPTION ----------------------------------------------------------------------------


- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    urlStr = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    if ([[urlStr substringToIndex:7] isEqual:@"feed://"]) {
        urlStr = [NSString stringWithFormat:@"http://%@", [urlStr substringFromIndex:7]];
    }
    
    [urlFlux setStringValue:urlStr];
    
    feedError = '\1';
    [self getTitle:[urlFlux stringValue]];
    
    
    
    
}

- (IBAction)ValidLogin:(id)sender {
    [NSApp endSheet:loginPanel];
    [loginPanel orderOut:self];
    [self getTitle:[NSString stringWithFormat:@"http://%@:%@@%@",[user stringValue] ,[pass stringValue],[urlStr substringFromIndex:7]]];
}

-(void)getTitle:(NSString*)url
{
    [urlFlux setStringValue:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    [request setHTTPMethod: @"GET"];
    NSError *requestError;
    NSURLResponse *urlResponse = nil;
    NSData *response1 = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
    
    NSLog(@"%@",requestError);
    NSXMLDocument* doc = [[NSXMLDocument alloc] initWithData:response1 options:0  error:NULL];
    NSMutableArray* titles = [[NSMutableArray alloc] initWithCapacity:0];
    
    NSXMLElement* root  = [doc rootElement];
    
    NSError *error;
    
    NSString * title = @"";
    NSArray* titleArray = [root nodesForXPath:@"//title" error:&error];
    
    NSLog(@"titre %@",titleArray);
    
    if (error)
    {
        NSLog(@"feederror");
        if (feedError){
            feedError = '\0';
            [NSApp beginSheet:loginPanel
               modalForWindow:(NSWindow *)selfossWindow
                modalDelegate:self
               didEndSelector:nil
                  contextInfo:nil];
        }
        else
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText: NSLocalizedString(@"Bad feed URL", @"Bad feed URL")];
            [alert setInformativeText: NSLocalizedString(@"impossible to initialize feed",@"impossible to initialize feed")];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert runModal];
            [alert release];
        }
    }
    else
    {
        for(NSXMLElement* xmlElement in titleArray)
            [titles addObject:[xmlElement stringValue]];
        title = [titles objectAtIndex:0];
        
        NSLog(@"titre %@",title);
        
        [titreFlux setStringValue:title];
        
        [self setTags];
        
        [NSApp beginSheet:addFluxWindow
           modalForWindow:(NSWindow *)selfossWindow
            modalDelegate:self
           didEndSelector:nil
              contextInfo:nil];
        
        [doc release];
        [titles release];
    }
}


- (void)AddFlux:(NSString*)title :(NSString*)categorie :(NSString*)urlduflux
{
    NSDictionary *params = @{
                             @"title":title,
                             @"spout":@"spouts\\rss\\feed",
                             @"filter":@"",
                             @"tags":categorie,
                             @"url":urlduflux
                             };
    NSMutableArray *pairs = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSString *key in params) {
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, params[key]]];
    }
    NSString *requestParams = [pairs componentsJoinedByString:@"&"];
    NSData *postData = [requestParams dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@source", [defaults stringForKey:selfossURL]]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    NSURLResponse *requestResponse;
    NSLog(@"requestData: %@", requestParams);
    NSError *error;
    NSData *requestHandler = [NSURLConnection sendSynchronousRequest:request returningResponse:&requestResponse error:&error];
    NSString *requestReply = [[NSString alloc] initWithBytes:[requestHandler bytes] length:[requestHandler length] encoding:NSASCIIStringEncoding];
    NSLog(@"requestReply: %@", requestReply);
    
    if (error)
    {
        
        NSDictionary *params = @{
                                 @"title":title,
                                 @"spout":@"spouts\\rss\\feed",
                                 @"tags":categorie,
                                 @"url":urlduflux
                                 };
        NSMutableArray *pairs = [[NSMutableArray alloc] initWithCapacity:0];
        for (NSString *key in params) {
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, params[key]]];
        }
        requestParams = [pairs componentsJoinedByString:@"&"];
        NSData *postData = [requestParams dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@source", [defaults stringForKey:selfossURL]]]];
        [request setHTTPMethod:@"POST"];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:postData];
        NSURLResponse *requestResponse;
        NSLog(@"requestData: %@", requestParams);
        NSError *error;
        NSData *requestHandler = [NSURLConnection sendSynchronousRequest:request returningResponse:&requestResponse error:&error];
        NSString *requestReply = [[NSString alloc] initWithBytes:[requestHandler bytes] length:[requestHandler length] encoding:NSASCIIStringEncoding];
        NSLog(@"requestReply: %@", requestReply);
        
        if (error)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText: NSLocalizedString(@"An error occurred",@"An error occurred")];
            [alert setInformativeText: NSLocalizedString(@"check your feed",@"check your feed")];
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert runModal];
            [alert release];
        }
    }
}

- (IBAction)validAdd:(id)sender {
    
    NSString *catfluxstring = [NSString stringWithFormat:@"%@, %@, %@",[catFluxBox stringValue], [catFluxBox2 stringValue], [catFluxBox3 stringValue]];
    
    
    NSString *resultUrlFlux = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[urlFlux stringValue], NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8));
    
    
    [self AddFlux:[titreFlux stringValue] :catfluxstring :resultUrlFlux];
    [NSApp endSheet:addFluxWindow];
    [addFluxWindow orderOut:self];
    
}

- (IBAction)AnnulAdd:(id)sender {
    [NSApp endSheet:addFluxWindow];
    [addFluxWindow orderOut:self];
    
}

- (void)setTags{
    
    NSError* error = nil;
    NSString *urlStringStats = [NSString stringWithFormat: @"%@tags", [defaults stringForKey:selfossURL]];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlStringStats] options:NSDataReadingUncached error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    else {
        [catFluxBox setUsesDataSource:NO];
        [catFluxBox2 setUsesDataSource:NO];
        [catFluxBox3 setUsesDataSource:NO];
        [catFluxBox removeAllItems];
        [catFluxBox2 removeAllItems];
        [catFluxBox3 removeAllItems];
        id allKeys = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        for (int i=0; i<[allKeys count]; i++)
        {
            NSDictionary *arrayResult = [allKeys objectAtIndex:i];
            [catFluxBox addItemWithObjectValue:[arrayResult objectForKey:@"tag"]];
            [catFluxBox2 addItemWithObjectValue:[arrayResult objectForKey:@"tag"]];
            [catFluxBox3 addItemWithObjectValue:[arrayResult objectForKey:@"tag"]];
        }
    }
}







// PREFERENCES --------------------------------------------------------------------


-(IBAction)makeSelfossDefault:(id)sender
{
    LSSetDefaultHandlerForURLScheme(feedScheme, bundleID);
    [checkdefault setEnabled: NO];
}

-(IBAction)validatePref:(id)sender
{
    
    if ([menuHiddenPref state] == NSOnState)
    {
        [defaults setObject:@"yes" forKey:selfossHide];
    }
    else
    {
        [defaults setObject:@"no" forKey:selfossHide];
    }
    
    
    
    if ([menuReloadPref state] == NSOnState)
    {
        [defaults setObject:@"reloadyes" forKey:selfossReload];
    }
    else
    {
        [defaults setObject:@"reloadno" forKey:selfossReload];
    }
    
    
    if ([menuFullscreen state] == NSOnState)
    {
        [defaults setObject:@"fullyes" forKey:selfossFullScreen];
    }
    else
    {
        [defaults setObject:@"fullno" forKey:selfossFullScreen];
    }
    
 
    if ([menuNotify state] == NSOnState)
    {
        [defaults setObject:@"notifyyes" forKey:selfossNotify];
    }
    else
    {
        [defaults setObject:@"notifyno" forKey:selfossNotify];
    }
    

    if ([menuAnim state] == NSOnState)
    {
        [defaults setObject:@"animyes" forKey:selfossAnim];
    }
    else
    {
        [defaults setObject:@"animno" forKey:selfossAnim];
    }
    
    
    if ([menuCheckUpdates state] == NSOnState)
    {
        [defaults setObject:@"checkyes" forKey:selfossCheck];
    }
    else
    {
        [defaults setObject:@"checkno" forKey:selfossCheck];
    }
    
    
    NSString *val;
    if([[selfossUrlField stringValue] hasSuffix:@"/"])
    {
        val = [selfossUrlField stringValue];
    }
    else
    {
        val = [NSString stringWithFormat: @"%@/",[selfossUrlField stringValue]];
    }
    
    
    NSError* error = nil;
    NSString *urlStringStats = [NSString stringWithFormat: @"%@stats", val];
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlStringStats] options:NSDataReadingUncached error:&error];
    NSLog(@"%@",data);
    
    if (error)
    {
        //  NSLog(@"%@", [error localizedDescription]);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        //[alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Selfoss URL"];
        [alert setInformativeText: NSLocalizedString(@"Not a valid Selfoss URL\nor protected with password",@"Not a valid Selfoss URL\nor protected with password")];
        [alert setAlertStyle:NSCriticalAlertStyle];
        
        if ([alert runModal] == NSAlertSecondButtonReturn) {
            [NSApp endSheet:prefPanel];
            [prefPanel orderOut:sender];
        }
        [alert release];
    }
    //else
    //{
        [defaults setObject:val forKey:selfossURL];
        [[selfossView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[defaults stringForKey:selfossURL]]]];
        [selfossUrlField setStringValue:[defaults stringForKey:selfossURL]];
        [NSApp endSheet:prefPanel];
        [prefPanel orderOut:sender];
        [self validTimerPref];
    //}
}

-(void)getTimerPref
{
    [defaults setObject:[slideTimeActive stringValue] forKey:selfossActive];
    [defaults setObject:[slideTimeUnactive stringValue] forKey:selfossUnactive];
}

-(void)validTimerPref
{
    activetime = [[[defaults stringForKey:selfossActive] stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] intValue];
    unactivetime = [[[defaults stringForKey:selfossUnactive] stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] intValue];
    [slideTimeActive setDoubleValue:activetime];
    [slideTimeUnactive setDoubleValue:unactivetime];
    [textTimeActive setStringValue:[NSString stringWithFormat:@"%d %@", activetime, NSLocalizedString(@"seconds (active app)", @"seconds (active app)")]];
    [textTimeUnactive setStringValue:[NSString stringWithFormat:@"%d %@", unactivetime, NSLocalizedString(@"minutes (inactive app)", @"minutes (inactive app)")]];
}

- (IBAction)valueChanged:(NSSlider *)sender {
    [self getTimerPref];
    [self validTimerPref];
    [self reloadtimer];
}

-(IBAction)openPrefPanel:(id)sender {
    
    [selfossUrlField setStringValue:[defaults stringForKey:selfossURL]];
    
    [NSApp beginSheet:prefPanel
       modalForWindow:(NSWindow *)selfossWindow
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
}




// WEBVIEW ??? ----------------------------------------------------------------

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{
    if( [sender isEqual:selfossView] ) {
        [listener use];
    }
    else {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
        [listener ignore];
    }
}



- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    WebView *newWebView = [[[WebView alloc] init] autorelease];
    [newWebView setHostWindow:selfossWindow];
    [newWebView setUIDelegate:self];
    [newWebView setPolicyDelegate:self];
    [newWebView setFrameLoadDelegate:self];
    [newWebView setGroupName:@"Selfoss"];
    return newWebView;
}

- (void)webView:(WebView *)webView didFailLoadWithError:(NSError *)error{
    NSLog(@"could not load the website caused by error: %@", error);
}



- (BOOL)webView:(WebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame {
    
    NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"Selfoss", @"Selfoss"),  // title
                                                    message,                // message
                                                    NSLocalizedString(@"OK", @"OK"),      // default button
                                                    NSLocalizedString(@"Cancel", @"Cancel"),    // alt button
                                                    nil);
    return NSAlertDefaultReturn == result;
}










// TIMERS ----------------------------------------------------------------------------

- (void)onTick:timer {
    NSLog(@"ontick2");
    [self badgeupdate];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

- (void)badgeupdate{
    [self launchAnim];
  
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError* error = nil;
        NSString *urlStringStats = [NSString stringWithFormat: @"%@stats", [defaults stringForKey:selfossURL]];
        NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlStringStats] options:NSDataReadingUncached error:&error];
        
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
        else {
            NSDictionary *response=[NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error:&error];
            NSDockTile *tile = [[NSApplication sharedApplication] dockTile];
            NSString *unread = [response objectForKey: @"unread"];
            
            int Nunread = [unread floatValue];
            int Ntilenumber = [tileNumber floatValue];
            int Nnew = Nunread - Ntilenumber;
            
            if ([unread isEqual: @"0"])
            {
                [tile setBadgeLabel:@""];
                [animTimer invalidate]; animTimer = nil;
                [NSApp setApplicationIconImage: [NSImage imageNamed:[NSString stringWithFormat:@"appl"] ]];
            }
            else
            {
                [tile setBadgeLabel:unread];
            }

            if ([[defaults stringForKey:selfossNotify] isEqualToString:@"notifyyes"]) {
                if (Ntilenumber < Nunread)  {
                    NSUserNotification *notification = [[NSUserNotification alloc] init];
                    notification.title = @"Selfoss";
                    notification.informativeText = [NSString stringWithFormat:@"%d %@",Nnew ,NSLocalizedString(@"new item(s) available",@"new item(s) available")];
                    notification.soundName = NSUserNotificationDefaultSoundName;
                    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
                }
            }
            tileNumber = unread;
        }
    });
}

- (void)appDidActivate:(NSNotification *)notification
{
    [self reloadtimer];
}

- (void)reloadtimer
{
    
    activetime = [[[defaults stringForKey:selfossActive] stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] intValue];
    unactivetime = [[[defaults stringForKey:selfossUnactive] stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] intValue];
    
    NSRunningApplication* runningApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    [timer invalidate]; timer = nil;
    
    
    if ([runningApp.bundleIdentifier isEqual: [[NSBundle mainBundle] bundleIdentifier]])
    {
        timer = [NSTimer scheduledTimerWithTimeInterval: (NSTimeInterval)activetime
                                                  target: self
                                                selector:@selector(onTick:)
                                                userInfo: nil repeats:YES];
    }
    else
    {
        timer = [NSTimer scheduledTimerWithTimeInterval:((NSTimeInterval)unactivetime*60)
                                                  target:self
                                                selector:@selector(onTick:)
                                                userInfo:nil
                                                 repeats:YES];
    }
    [self badgeupdate];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag{
    [selfossWindow setIsVisible:YES];
    
    if ([[defaults stringForKey:selfossReload] isEqualToString:@"yes"])
    {
        [[selfossView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[defaults stringForKey:selfossURL]]]];
    }
    
    [self reloadtimer];
    return YES;
}






// ACTION ICON ----------------------------------------------------------------------------

- (IBAction)seeNewest:(id)sender {
    [selfossWindow makeFirstResponder:selfossView];
    CGEventRef event = CGEventCreateKeyboardEvent( NULL, 0, true );
    UniChar oneChar = 'n';
    CGEventKeyboardSetUnicodeString(event, 1, &oneChar);
    CGEventSetFlags(event, kCGEventFlagMaskShift);
    CGEventPost(kCGSessionEventTap, event);
}

- (IBAction)seeUnread:(id)sender {
    [selfossWindow makeFirstResponder:selfossView];
    CGEventRef event = CGEventCreateKeyboardEvent( NULL, 0, true );
    UniChar oneChar = 'u';
    CGEventKeyboardSetUnicodeString(event, 1, &oneChar);
    CGEventSetFlags(event, kCGEventFlagMaskShift);
    CGEventPost(kCGSessionEventTap, event);
}

- (IBAction)seeStared:(id)sender {
    [selfossWindow makeFirstResponder:selfossView];
    CGEventRef event = CGEventCreateKeyboardEvent( NULL, 0, true );
    UniChar oneChar = 's';
    CGEventKeyboardSetUnicodeString(event, 1, &oneChar);
    CGEventSetFlags(event, kCGEventFlagMaskShift);
    CGEventPost(kCGSessionEventTap, event);
}

- (IBAction)markallasread:(id)sender {
    [selfossWindow makeFirstResponder:selfossView];
    CGEventRef event = CGEventCreateKeyboardEvent( NULL, 0, true );
    UniChar oneChar = 'm';
    CGEventKeyboardSetUnicodeString(event, 1, &oneChar);
    CGEventSetFlags(event, kCGEventFlagMaskControl);
    CGEventPost(kCGSessionEventTap, event);
    [self badgeupdate];
}

- (IBAction)hideMenu:(id)sender {
    [self hideMenu2];
}

- (void)hideMenu2 {
    if (([hidemenu isEqual:@"1"])){
        NSRect webViewRect = [selfossView frame];
        NSRect newWebViewRect = NSMakeRect(webViewRect.origin.x - 180, webViewRect.origin.y, NSWidth(webViewRect)+180, NSHeight(webViewRect));
        [selfossView setFrame:newWebViewRect];
        hidemenu=@"0";
    }
    else{
        NSRect webViewRect = [selfossView frame];
        NSRect newWebViewRect = NSMakeRect(webViewRect.origin.x + 180, webViewRect.origin.y, NSWidth(webViewRect) - 180, NSHeight(webViewRect));
        [selfossView setFrame:newWebViewRect];
        hidemenu=@"1";
    }
}

- (IBAction)github:(id)sender {
    [NSApp endSheet:prefPanel];
    [prefPanel orderOut:sender];
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://github.com/dimitrifontaine/selfoss-mac-client"]];
}

-(void)launchAnim {
    if (![animTimer isValid] && [[defaults stringForKey:selfossAnim] isEqualToString:@"animyes"])
    {
        
        animTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                     target:self
                                                   selector:@selector(updateImage:)
                                                   userInfo:NULL
                                                    repeats:YES];
    }
    
}

- (void)updateImage:(NSTimer*)timer
{
    currentFrame++;
    NSLog(@"anim %d",currentFrame);
    [NSApp setApplicationIconImage: [NSImage imageNamed:[NSString stringWithFormat:@"selfoss0%d", currentFrame]]];
    if (currentFrame == 4) {currentFrame = 0;}
}

@end
