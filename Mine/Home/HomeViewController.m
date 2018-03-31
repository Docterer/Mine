//
//  HomeViewController.m
//  Mine
//
//  Created by 单怡然 on 2018/3/30.
//  Copyright © 2018年 单怡然. All rights reserved.
//

#import "HomeViewController.h"

@interface HomeViewController ()
@property WebViewJavascriptBridge* bridge;
//@property(retain,nonatomic) UIActivityIndicatorView *activityIndicator;
@end

@implementation HomeViewController{
    NSString *htmlLogin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = YES;
    
    // 开启日志
    [WebViewJavascriptBridge enableLogging];
//    NSHTTPCookieStorage *cook = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    [cook setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    //将webview与webviewJavascriptBridge关联
    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
    }];
    
    
    //注册OC方法提供给JS调用示范
//    [_bridge registerHandler:@"getAccAndIp" handler:^(id data, WVJBResponseCallback responseCallback) {
//
//        NSDictionary *WAN_INFO = [NetWorkTool deviceWANInfo];
//
//        NSString *pubipaddr = WAN_INFO[@"ip"];
//        NSString *intranetaddr = [NetWorkTool getIpAddresses];
//        NSString *iplocation = [NSString stringWithFormat:@"%@%@ %@",WAN_INFO[@"region"],WAN_INFO[@"city"],WAN_INFO[@"country"]];
//
//        NSDictionary *param = @{@"pubipaddr":pubipaddr,@"intranetaddr":intranetaddr,@"iplocation":iplocation};
//
//        responseCallback(param);
//    }];
    
    [_bridge registerHandler:@"tryTouchIOS" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"js传过来的参数---->  %@",data);
        responseCallback(@"谁在呼喊");
    }];
    
    
    //OC调用JS方法示例
    [_bridge callHandler:@"isConn" data:@"是你吗，你给我一双翅膀" responseCallback:^(id responseData){
        NSLog(@"🤡🤡🤡JS确定收到数据的回调:%@",responseData);
    }];
    
    
    
    
    
    
    //添加静态页面到本地
    
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
    htmlLogin = [[NSBundle mainBundle] pathForResource:@"index"ofType:@"html"inDirectory:@"assets/"];
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
