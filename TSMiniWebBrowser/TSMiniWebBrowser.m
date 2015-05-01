//
//  TSMiniWebBrowser.m
//  TSMiniWebBrowserDemo
//
//  Created by Toni Sala Echaurren on 18/01/12.
//  Copyright 2012 Toni Sala. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "TSMiniWebBrowser.h"

@interface TSMiniWebBrowser ()
@property (nonatomic, retain) UIActionSheet* actionSheet;
@end

@implementation TSMiniWebBrowser

@synthesize delegate;
@synthesize mode;
@synthesize showURLStringOnActionSheetTitle;
@synthesize showPageTitleOnTitleBar;
@synthesize showReloadButton;
@synthesize showActionButton;
@synthesize barStyle;
@synthesize modalDismissButtonTitle;

#pragma mark - Private Methods

-(void)setTitleBarText:(NSString*)pageTitle {
    if (mode == TSMiniWebBrowserModeModal) {
        navigationBarModal.topItem.title = pageTitle;
        
    } else if(mode == TSMiniWebBrowserModeNavigation) {
        if(pageTitle) [[self navigationItem] setTitle:pageTitle];
    }
}

-(void) toggleBackForwardButtons {
    buttonGoBack.enabled = webView.canGoBack;
    buttonGoForward.enabled = webView.canGoForward;
}

-(void)showActivityIndicators {
    [activityIndicator setHidden:NO];
    [activityIndicator startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)hideActivityIndicators {
    [activityIndicator setHidden:YES];
    [activityIndicator stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void) dismissController {
    [self dismissViewControllerAnimated:YES completion:^{
        // Notify the delegate
        if ([self.delegate respondsToSelector:@selector(tsMiniWebBrowserDidDismiss)]) {
            [self->delegate tsMiniWebBrowserDidDismiss];
        }
    }];
    
}

//Added in the dealloc method to remove the webview delegate, because if you use this in a navigation controller
//TSMiniWebBrowser can get deallocated while the page is still loading and the web view will call its delegate-- resulting in a crash
- (void)dealloc
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[webView setDelegate:nil];
	[webView stopLoading];
    [super dealloc];
}

#pragma mark - Init

-(void) initTitleBar {
    UIBarButtonItem *buttonDone = [[[UIBarButtonItem alloc] initWithTitle:modalDismissButtonTitle style:UIBarButtonItemStyleBordered target:self action:@selector(dismissController)] autorelease];
    
    UINavigationItem *titleBar = [[[UINavigationItem alloc] initWithTitle:@""] autorelease];
    titleBar.leftBarButtonItem = buttonDone;
    
    CGFloat width = self.view.frame.size.width;
    navigationBarModal = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, 44)] autorelease];
    //navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    navigationBarModal.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    navigationBarModal.barStyle = barStyle;
    [navigationBarModal pushNavigationItem:titleBar animated:NO];
    
    [self.view addSubview:navigationBarModal];
}

-(void) initToolBar {
    if (mode == TSMiniWebBrowserModeNavigation) {
        self.navigationController.navigationBar.barStyle = barStyle;
    }
    
    CGSize viewSize = self.view.frame.size;
    if (mode == TSMiniWebBrowserModeTabBar) {
        toolBar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, -1, viewSize.width, kToolBarHeight)] autorelease];
    } else {
        toolBar = [[[UIToolbar alloc] initWithFrame:CGRectMake(0, viewSize.height-kToolBarHeight, viewSize.width, kToolBarHeight)] autorelease];
    }
	if ([toolBar respondsToSelector:@selector(barTintColor)])
	{
		toolBar.barTintColor = [UIColor whiteColor];
	}

	self.view.backgroundColor = [UIColor whiteColor];
    
    toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    toolBar.barStyle = barStyle;
    [self.view addSubview:toolBar];
    
    buttonGoBack = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back_icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonTouchUp:)] autorelease];
    [buttonGoBack setAccessibilityLabel:@"Back Button"];
	
    UIBarButtonItem *fixedSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
    fixedSpace.width = 30;
    
    buttonGoForward = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward_icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(forwardButtonTouchUp:)] autorelease];
    [buttonGoForward setAccessibilityLabel:@"Forward Button"];
	
    UIBarButtonItem *flexibleSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    
    UIBarButtonItem *buttonReload = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"reload_icon.png"] style:UIBarButtonItemStylePlain target:self action:@selector(reloadButtonTouchUp:)] autorelease];
    [buttonReload setAccessibilityLabel:@"Reload Button"];
	
    UIBarButtonItem *fixedSpace2 = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];
    fixedSpace2.width = 20;
    
    UIBarButtonItem *buttonAction = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(buttonActionTouchUp:)] autorelease];
    [buttonAction setAccessibilityLabel:@"Action Button"];
	
    // Activity indicator is a bit special
    activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    activityIndicator.frame = CGRectMake(11, 7, 20, 20);
    UIView *containerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 43, 33)] autorelease];
    [containerView addSubview:activityIndicator];
    UIBarButtonItem *buttonContainer = [[[UIBarButtonItem alloc] initWithCustomView:containerView] autorelease];
    
    // Add butons to an array
    NSMutableArray *toolBarButtons = [[[NSMutableArray alloc] init] autorelease];
    [toolBarButtons addObject:buttonGoBack];
    [toolBarButtons addObject:fixedSpace];
    [toolBarButtons addObject:buttonGoForward];
    [toolBarButtons addObject:flexibleSpace];
    [toolBarButtons addObject:buttonContainer];
    if (showReloadButton) { 
        [toolBarButtons addObject:buttonReload];
    }
    if (showActionButton) {
        [toolBarButtons addObject:fixedSpace2];
        [toolBarButtons addObject:buttonAction];
    }
    
    // Set buttons to tool bar
    [toolBar setItems:toolBarButtons animated:YES];
}

-(void) initWebView {
    CGSize viewSize = self.view.frame.size;
    if (mode == TSMiniWebBrowserModeModal) {
        webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, kToolBarHeight, viewSize.width, viewSize.height-kToolBarHeight*2)] autorelease];
    } else if(mode == TSMiniWebBrowserModeNavigation) {
        webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, viewSize.width, viewSize.height-kToolBarHeight)] autorelease];
    } else if(mode == TSMiniWebBrowserModeTabBar) {
        self.view.backgroundColor = [UIColor redColor];
        webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, kToolBarHeight-1, viewSize.width, viewSize.height-kToolBarHeight+1)] autorelease];
    }
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:webView];
    
    webView.scalesPageToFit = YES;
    
    webView.delegate = self;
    
    // Load the URL in the webView
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:self.urlToLoad];
    [webView loadRequest:requestObj];
}

#pragma mark -

- (id)initWithUrl:(NSURL*)url {
    self = [self init];
    if(self)
    {
        self.urlToLoad = url;
        
        // Defaults
        mode = TSMiniWebBrowserModeNavigation;
        showURLStringOnActionSheetTitle = YES;
        showPageTitleOnTitleBar = YES;
        showReloadButton = YES;
        showActionButton = YES;
        modalDismissButtonTitle = NSLocalizedString(@"Done", nil);
        forcedTitleBarText = nil;
    }
    
    return self;
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
	if (string == nil)
	{
		[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
	}
	else
	{
		[webView loadHTMLString:string baseURL:baseURL];
	}
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Main view frame.
    if (mode == TSMiniWebBrowserModeTabBar) {
        CGFloat viewWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat viewHeight = [UIScreen mainScreen].bounds.size.height - kTabBarHeight;
        if (![UIApplication sharedApplication].statusBarHidden) {
            viewHeight -= [UIApplication sharedApplication].statusBarFrame.size.height;
        }
        self.view.frame = CGRectMake(0, 0, viewWidth, viewHeight);
    }
    
    // Store the current navigationBar bar style to be able to restore it later.
    if (mode == TSMiniWebBrowserModeNavigation) {
        originalBarStyle = self.navigationController.navigationBar.barStyle;
    }
    
    // Init tool bar
    [self initToolBar];
    
    // Init web view
    [self initWebView];
    
    // Init title bar if presented modally
    if (mode == TSMiniWebBrowserModeModal) {
        [self initTitleBar];
    }
    
    // UI state
    buttonGoBack.enabled = NO;
    buttonGoForward.enabled = NO;
    if (forcedTitleBarText != nil) {
        [self setTitleBarText:forcedTitleBarText];
    }
    
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Restore navigationBar bar style.
    if (mode == TSMiniWebBrowserModeNavigation) {
        self.navigationController.navigationBar.barStyle = originalBarStyle;
    }
}

- (BOOL)shouldAutorotate;
{
    return YES;
}

/* Fix for landscape + zooming webview bug.
 * If you experience perfomance problems on old devices ratation, comment out this method.
 */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    CGFloat ratioAspect = webView.bounds.size.width/webView.bounds.size.height;
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
            // Going to Portrait mode
            for (UIScrollView *scroll in [webView subviews]) { //we get the scrollview 
                // Make sure it really is a scroll view and reset the zoom scale.
                if ([scroll respondsToSelector:@selector(setZoomScale:)]){
                    scroll.minimumZoomScale = scroll.minimumZoomScale/ratioAspect;
                    scroll.maximumZoomScale = scroll.maximumZoomScale/ratioAspect;
                    [scroll setZoomScale:(scroll.zoomScale/ratioAspect) animated:YES];
                }
            }
            break;
        default:
            // Going to Landscape mode
            for (UIScrollView *scroll in [webView subviews]) { //we get the scrollview 
                // Make sure it really is a scroll view and reset the zoom scale.
                if ([scroll respondsToSelector:@selector(setZoomScale:)]){
                    scroll.minimumZoomScale = scroll.minimumZoomScale *ratioAspect;
                    scroll.maximumZoomScale = scroll.maximumZoomScale *ratioAspect;
                    [scroll setZoomScale:(scroll.zoomScale*ratioAspect) animated:YES];
                }
            }
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark Current url

- (NSURL*)currentURL
{
	//If the webview fails to load the url is bogus. return self.urlToLoad
	BOOL hasValidWebUrl = [[[webView.request URL] description] length] > 0;
	return hasValidWebUrl ? [webView.request URL] : self.urlToLoad;
}

#pragma mark - Action Sheet

-(NSString *)actionSheetTitle{
	NSString *urlString = @"";
    if (showURLStringOnActionSheetTitle) {
        NSURL* url = [self currentURL];
		urlString = [url absoluteString];
		if([[url absoluteString] length] > kTSMaxURLActionSheetLabelLength)
		{
			urlString = [NSString stringWithFormat:@"%@...",[[url absoluteString] substringToIndex:kTSMaxURLActionSheetLabelLength]];
		}
    }
	
	return urlString;
}

-(NSString *)actionSheetButtonTitle{
	return @"Open in Safari";
}

- (void)showActionSheet:(UIBarButtonItem *)button
{
	if (self.actionSheet == nil)
	{
		self.actionSheet = [[UIActionSheet alloc] initWithTitle:[self actionSheetTitle]
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										 destructiveButtonTitle:nil
											  otherButtonTitles:NSLocalizedString([self actionSheetButtonTitle], nil),  nil];
		
		_actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
		
		if (mode == TSMiniWebBrowserModeTabBar)
		{
			[_actionSheet showInView:self.tabBarController.view];
		}
		else
		{
			[_actionSheet showFromBarButtonItem:button animated:YES];
		}
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	switch(buttonIndex) {
		case 0:
			// Open in Safari
            [[UIApplication sharedApplication] openURL:[self currentURL]];
			break;
		default:
			break;
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	self.actionSheet = nil;
}


#pragma mark - Actions

- (void)backButtonTouchUp:(id)sender {
    [webView goBack];
    
    [self toggleBackForwardButtons];
}

- (void)forwardButtonTouchUp:(id)sender {
    [webView goForward];
    
    [self toggleBackForwardButtons];
}

- (void)reloadButtonTouchUp:(id)sender {
    [webView reload];
    
    [self toggleBackForwardButtons];
}

- (void)buttonActionTouchUp:(id)sender {
    [self showActionSheet:sender];
}

#pragma mark - Public Methods

- (void)setFixedTitleBarText:(NSString*)newTitleBarText {
    forcedTitleBarText = newTitleBarText;
    showPageTitleOnTitleBar = NO;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	
    if ([[request.URL absoluteString] hasPrefix:@"http://itunes.apple.com/"] ||
        [[request.URL absoluteString] hasPrefix:@"http://phobos.apple.com/"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
	
	// Handle alternate URL schemes
	if ([[[request URL] scheme] isEqual:@"mailto"] ||
		[[[request URL] scheme] isEqual:@"callto"] ||
		[[[request URL] scheme] isEqual:@"tel"] ||
		[[[request URL] scheme] isEqual:@"sms"]) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self toggleBackForwardButtons];
    
    [self showActivityIndicators];
}

- (void)webViewDidFinishLoad:(UIWebView *)_webView {
	if ([self.delegate respondsToSelector:@selector(tsMiniWebBrowserDidLoad:)]) {
		[self.delegate tsMiniWebBrowserDidLoad:webView.request.URL];
	}
    // Show page title on title bar?
    if (showPageTitleOnTitleBar) {
        NSString *pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        [self setTitleBarText:pageTitle];
    }
    
    [self hideActivityIndicators];
    
    [self toggleBackForwardButtons];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {	
    [self hideActivityIndicators];
	
	if ([error code] == NSURLErrorCancelled) return;
    
    // Show error alert
#ifndef RUN_KIF_TESTS
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could not load page", nil)
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
	[alert show];
#endif
}

@end
