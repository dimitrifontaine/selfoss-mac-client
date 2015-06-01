//
//  AppDelegate.m
//  Selfoss
//
//  Created by Dimitri on 01/10/13.
//  Copyright (c) 2014 Graphic-identité. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

#define selfossURL @"http://selfoss.aditu.de/"
#define selfossActive @"5"
#define selfossUnactive @"15"
#define selfossHide @"yes"
#define selfossReload @"no"

- (id)init {
    
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
    
    defaults = [NSUserDefaults standardUserDefaults];
    

    BOOL firstLaunch = '\0';
    
    if ([defaults stringForKey:selfossActive] == nil)[defaults setObject:@"5" forKey:selfossActive];
    if ([defaults stringForKey:selfossUnactive] == nil)[defaults setObject:@"10" forKey:selfossUnactive];
    if ([defaults stringForKey:selfossHide] == nil)[defaults setObject:@"yes" forKey:selfossHide];
    if ([defaults stringForKey:selfossReload] == nil)[defaults setObject:@"no" forKey:selfossReload];
   
    if ([defaults stringForKey:selfossURL] == nil){
        [defaults setObject:@"http://selfoss.aditu.de/" forKey:selfossURL];
        firstLaunch = '\1';
    }
  
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

    if ([[defaults stringForKey:selfossReload] isEqualToString:@"yes"])
    {
        [menuReloadPref setState:NSOnState];
    }
    else
    {
        [menuReloadPref setState:NSOffState];
    }

    [selfossUrlField setStringValue:[defaults stringForKey:selfossURL]];
    
    
    
    
    
    [selfossWindow setReleasedWhenClosed:NO];
    [selfossView setHostWindow:selfossWindow];
    [selfossView setPolicyDelegate:self];
    [selfossView setUIDelegate:self];
    [selfossView setFrameLoadDelegate:self];
    [selfossView setGroupName:@"Selfoss"];
    [selfossView setShouldUpdateWhileOffscreen:YES];
    [[selfossView preferences] setJavaScriptCanOpenWindowsAutomatically:YES];
    //  [[selfossView preferences] setUsesPageCache:YES];
    //  [[selfossView preferences] setCacheModel:WebCacheModelPrimaryWebBrowser];
    [[selfossView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[defaults stringForKey:selfossURL]]]];
    

    if (firstLaunch)    [NSApp beginSheet:prefPanel
                           modalForWindow:(NSWindow *)selfossWindow
                            modalDelegate:self
                           didEndSelector:nil
                              contextInfo:nil];
    [self reloadtimer];
    // [self redirectConsoleLogToDocumentFolder];
    
    
    
}

- (void) redirectConsoleLogToDocumentFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"selfoss.log"];
    freopen([logPath fileSystemRepresentation],"a+",stderr);
}








// HANDLE FEED + ADD SUBSCRIPTION ----------------------------------------------------------------------------


- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    urlStr = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    if ([[urlStr substringToIndex:7] isEqual:@"feed://"]) {
        urlStr = [NSString stringWithFormat:@"http://%@", [urlStr substringFromIndex:7]];
    }
    
    
    [urlFlux setStringValue:urlStr];
    NSString* url = [urlFlux stringValue];
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    [request setHTTPMethod: @"GET"];
    NSError *requestError;
    NSURLResponse *urlResponse = nil;
    NSData *response1 = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
    NSXMLDocument* doc = [[NSXMLDocument alloc] initWithData:response1 options:0  error:NULL];
    NSMutableArray* titles = [[NSMutableArray alloc] initWithCapacity:1];
    
    
    NSXMLElement* root  = [doc rootElement];
    
    NSArray* titleArray = [root nodesForXPath:@"//title" error:nil];
    for(NSXMLElement* xmlElement in titleArray)
        [titles addObject:[xmlElement stringValue]];
    
    
    NSString * title = [titles objectAtIndex:0];
    
    NSLog(@"%@",title);
    
    [titreFlux setStringValue:title];
    [catFlux setStringValue:@""];
    
    
    [NSApp beginSheet: addFluxWindow modalForWindow: selfossWindow modalDelegate: self didEndSelector: @selector(customSheetDidClose:returnCode:contextInfo:) contextInfo: nil];
    
    
    
    [doc release];
    
    [titles release];
}

- (void)AddFlux:(NSString*)title :(NSString*)categorie :(NSString*)urlduflux
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
    
    NSString *requestParams = [pairs componentsJoinedByString:@"&"];
    
    
    NSLog(@"%@",requestParams);
    
    NSData *postData = [requestParams dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@source", [defaults stringForKey:selfossURL]]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    
    NSURLResponse *requestResponse;
    NSData *requestHandler = [NSURLConnection sendSynchronousRequest:request returningResponse:&requestResponse error:nil];
    
    NSString *requestReply = [[NSString alloc] initWithBytes:[requestHandler bytes] length:[requestHandler length] encoding:NSASCIIStringEncoding];
    NSLog(@"requestReply: %@", requestReply);
    
}

- (IBAction)validAdd:(id)sender {
    [self AddFlux:[titreFlux stringValue] :[catFlux stringValue] :[urlFlux stringValue]];
    [addFluxWindow orderOut:self];
    [NSApp endSheet:addFluxWindow];
}

- (IBAction)AnnulAdd:(id)sender {
    [addFluxWindow orderOut:self];
    [NSApp endSheet:addFluxWindow];
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
        [defaults setObject:@"yes" forKey:selfossReload];
    }
    else
    {
        [defaults setObject:@"no" forKey:selfossReload];
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
        NSLog(@"%@", [error localizedDescription]);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Bad Selfoss URL"];
        [alert setInformativeText:@"it's not a valid Selfoss URL"];
        [alert setAlertStyle:NSCriticalAlertStyle];
        
        if ([alert runModal] == NSAlertSecondButtonReturn) {
            [NSApp endSheet:prefPanel];
            [prefPanel orderOut:sender];
        }
        [alert release];
    }
    else
    {
        [defaults setObject:val forKey:selfossURL];
        [[selfossView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[defaults stringForKey:selfossURL]]]];
        [selfossUrlField setStringValue:[defaults stringForKey:selfossURL]];
        [NSApp endSheet:prefPanel];
        [prefPanel orderOut:sender];
        [self validTimerPref];
    }
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
    [textTimeActive setStringValue:[NSString stringWithFormat:@"%d seconds when active", activetime]];
    [textTimeUnactive setStringValue:[NSString stringWithFormat:@"%d minutes when inactive", unactivetime]];
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















// TIMERS ----------------------------------------------------------------------------

- (void)onTick:timer {
       [self badgeupdate];
}

- (void)badgeupdate{
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
            if ([unread isEqual: @"0"]){[tile setBadgeLabel:@""];}
            else{[tile setBadgeLabel:unread];}
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
    [_timer invalidate];
    
    
    if ([runningApp.bundleIdentifier isEqual: [[NSBundle mainBundle] bundleIdentifier]])
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval: (NSTimeInterval)activetime
                                                  target: self
                                                selector:@selector(onTick:)
                                                userInfo: nil repeats:YES];
    }
    else
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:((NSTimeInterval)unactivetime*60)
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

- (IBAction)paypalDonation:(id)sender {
    [NSApp endSheet:prefPanel];
    [prefPanel orderOut:sender];
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=FHST6RQCCTGLS&lc=FR&item_name=Selfoss%20client&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHosted"]];
}


@end
