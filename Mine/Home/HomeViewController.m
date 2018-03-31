//
//  HomeViewController.m
//  Mine
//
//  Created by 单怡然 on 2018/3/30.
//  Copyright © 2018年 单怡然. All rights reserved.
//

#import "HomeViewController.h"
//识别功能
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"

//唤醒功能
#import "BDSWakeupDefines.h"
#import "BDSWakeupParameters.h"

//#error "请在官网新建应用，配置包名，并在此填写应用的 api key, secret key, appid(即appcode)"
const NSString* API_KEY = @"";
const NSString* SECRET_KEY = @"";
const NSString* APP_ID = @"";

@interface HomeViewController ()

@property (strong, nonatomic) BDSEventManager *asrEventManager;
@property (strong, nonatomic) BDSEventManager *wakeupEventManager;

@property WebViewJavascriptBridge* bridge;
//@property(retain,nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation HomeViewController{
    NSString *htmlLogin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = YES;
    self.asrEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
    //创建语音识别对象
    self.wakeupEventManager = [BDSEventManager createEventManagerWithName:BDS_WAKEUP_NAME];
    // 设置语音唤醒代理
    [self.wakeupEventManager setDelegate:self];
    // 参数配置：离线授权APPID
    [self.wakeupEventManager setParameter:APP_ID forKey:BDS_WAKEUP_APP_CODE];
    // 参数配置：唤醒语言模型文件路径, 默认文件名为 bds_easr_basic_model.dat
    [self.wakeupEventManager setParameter:@"唤醒语言模型文件路径" forKey:BDS_WAKEUP_DAT_FILE_PATH];
    // 发送指令：加载语音唤醒引擎
    [self.wakeupEventManager sendCommand:BDS_WP_CMD_LOAD_ENGINE];
    //设置唤醒词文件路径
    // 默认的唤醒词文件为"bds_easr_wakeup_words.dat"，包含的唤醒词为"百度一下"
    // 如需自定义唤醒词，请在 http://ai.baidu.com/tech/speech/wake 中评估并下载唤醒词文件，替换此参数
    [self.asrEventManager setParameter:@"唤醒词文件路径" forKey:BDS_WAKEUP_WORDS_FILE_PATH];
    // 发送指令：启动唤醒
    [self.wakeupEventManager sendCommand:BDS_WP_CMD_START];
    
    //注册键盘弹出通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    //注册键盘隐藏通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
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
//开始唤醒
- (void)startWakeup
{
    [self configWakeupClient];
    [self.wakeupEventManager setParameter:nil forKey:BDS_WAKEUP_AUDIO_FILE_PATH];
    [self.wakeupEventManager setParameter:nil forKey:BDS_WAKEUP_AUDIO_INPUT_STREAM];
    [self.wakeupEventManager sendCommand:BDS_WP_CMD_LOAD_ENGINE];
    [self.wakeupEventManager sendCommand:BDS_WP_CMD_START];
}
//结束唤醒
- (void)stopWakeup
{
    [self.wakeupEventManager sendCommand:BDS_WP_CMD_STOP];
    [self.wakeupEventManager sendCommand:BDS_WP_CMD_UNLOAD_ENGINE];
}

- (void)configWakeupClient {
    
    [self.wakeupEventManager setDelegate:self];
    [self.wakeupEventManager setParameter:APP_ID forKey:BDS_WAKEUP_APP_CODE];
    
    [self configWakeupSettings];
}

- (void)configWakeupSettings {
    NSString* dat = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
    
    // 默认的唤醒词为"百度一下"，如需自定义唤醒词，请在 http://ai.baidu.com/tech/speech/wake 中评估并下载唤醒词，替换此参数
    NSString* words = [[NSBundle mainBundle] pathForResource:@"bds_easr_wakeup_words" ofType:@"dat"];
    [self.wakeupEventManager setParameter:dat forKey:BDS_WAKEUP_DAT_FILE_PATH];
    [self.wakeupEventManager setParameter:words forKey:BDS_WAKEUP_WORDS_FILE_PATH];
}

- (void)configOfflineClient {
    
    // 离线仅可识别自定义语法规则下的词
    NSString* gramm_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_gramm" ofType:@"dat"];;
    NSString* lm_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];;
    NSString* wakeup_words_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_wakeup_words" ofType:@"dat"];;
    [self.asrEventManager setDelegate:self];
    [self.asrEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
    [self.asrEventManager setParameter:lm_filepath forKey:BDS_ASR_OFFLINE_ENGINE_DAT_FILE_PATH];
    // 请在 (官网)[http://speech.baidu.com/asr] 参考模板定义语法，下载语法文件后，替换BDS_ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH参数
    [self.asrEventManager setParameter:gramm_filepath forKey:BDS_ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH];
    [self.asrEventManager setParameter:wakeup_words_filepath forKey:BDS_ASR_OFFLINE_ENGINE_WAKEUP_WORDS_FILE_PATH];
    
}

- (void)configRecognizerViewController {
//    BDRecognizerViewParamsObject *paramsObject = [[BDRecognizerViewParamsObject alloc] init];
//    paramsObject.isShowTipAfterSilence = YES;
//    paramsObject.isShowHelpButtonWhenSilence = NO;
//    paramsObject.tipsTitle = @"您可以这样问";
//    paramsObject.tipsList = [NSArray arrayWithObjects:@"我要吃饭", @"我要买电影票", @"我要订酒店", nil];
//    paramsObject.waitTime2ShowTip = 0.5;
//    paramsObject.isHidePleaseSpeakSection = YES;
//    paramsObject.disableCarousel = YES;
//    self.recognizerViewController = [[BDRecognizerViewController alloc] initRecognizerViewControllerWithOrigin:CGPointMake(9, 80)
//                 theme:nil
//      enableFullScreen:YES
//          paramsObject:paramsObject
//              delegate:self];
}

- (void)configFileHandler {
    //self.fileHandler = [self createFileHandleWithName:@"recoder.pcm" isAppend:NO];
}


//键盘弹出后将视图向上移动
-(void)keyboardWillShow:(NSNotification *)note

{
    
    NSDictionary *info = [note userInfo];
    
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    //目标视图UITextField
    
    CGRect frame = _webView.frame;
    
    int y = frame.origin.y + frame.size.height - (self.view.frame.size.height - keyboardSize.height);
    
    NSTimeInterval animationDuration = 0.30f;
    
    [UIView beginAnimations:@"ResizeView" context:nil];
    
    [UIView setAnimationDuration:animationDuration];
    
    if(y > 0)
        
    {
        
        self.view.frame = CGRectMake(0, -y, self.view.frame.size.width, self.view.frame.size.height);
        
    }
    
    [UIView commitAnimations];
    
}



//键盘隐藏后将视图恢复到原始状态

-(void)keyboardWillHide:(NSNotification *)note

{
    
    NSTimeInterval animationDuration = 0.30f;
    
    [UIView beginAnimations:@"ResizeView" context:nil];
    
    [UIView setAnimationDuration:animationDuration];
    
    self.view.frame =CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [UIView commitAnimations];
    
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
