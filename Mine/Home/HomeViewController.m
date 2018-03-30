//
//  HomeViewController.m
//  Mine
//
//  Created by 单怡然 on 2018/3/30.
//  Copyright © 2018年 单怡然. All rights reserved.
//

#import "HomeViewController.h"

@interface HomeViewController ()
//@property(retain,nonatomic) UIActivityIndicatorView *activityIndicator;
@end

@implementation HomeViewController{
    NSString *htmlLogin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //第三步：添加
    [self.view addSubview:self.webView];
    //[self.view addSubview:self.activityIndicator];
    [self loadUrl];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadUrl
{
    //第二步：加载服务器url，实现代理方法。-----注意点拦截url解决webview加载本地连接不显示问题
    htmlLogin = [[NSBundle mainBundle] pathForResource:@"index"ofType:@"html"inDirectory:@"webapp/"];
    NSLog(@"2222%@",htmlLogin);
    NSURL* htmlUrl = [NSURL fileURLWithPath:htmlLogin];
    NSURLRequest* request = [NSURLRequest requestWithURL:htmlUrl];
    [self.webView loadRequest:request];
    
}
#pragma mark -- 懒加载
- (UIWebView *)webView{
    //第一步：懒加载。
    if (!_webView) {
        _webView = ({
            UIWebView * webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width, self.view.bounds.size.height-20)];
            webView.delegate = self;
            webView.dataDetectorTypes = UIDataDetectorTypeAll;
            webView.scalesPageToFit = YES;//自动对页面进行缩放以适应屏幕
            webView.scrollView.bounces = NO ;//禁止回弹方法
            webView;
        });
    }
    return _webView;
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    //[self.activityIndicator startAnimating] ;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{
    //[self.activityIndicator stopAnimating];
    //禁用长按触控对象弹出的菜单
    [_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    //设置导航头
    NSString *title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.title=title;
    NSLog(@"webViewDidFinishLoad");
    if ([webView.request.URL.absoluteString isEqualToString:@"about:blank"]
        && ![webView canGoBack] && [webView canGoForward]) {
    }
    //去掉事件
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    // Disable callout
    [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
    //禁止回弹滚动
    webView.scrollView.bounces = NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSLog(@"url 22222%@", [[request URL] absoluteString]);//做页面拦截
    return YES;
}

-(void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{//加载失败
    NSLog(@"🐶url %@", error);//做页面拦截
}

@end
