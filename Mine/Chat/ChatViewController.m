//
//  ChatViewController.m
//  Mine
//
//  Created by 单怡然 on 2018/4/2.
//  Copyright © 2018年 单怡然. All rights reserved.
//

#import "ChatViewController.h"
//语音识别功能
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"
#import "BDRecognizerViewController.h"
#import "fcntl.h"
//#import "AudioInputStream.h"

//#error "请在官网新建应用，配置包名，并在此填写应用的 api key, secret key, appid(即appcode)"
const NSString* API_KEY = @"PmrwnGrMkF5UtjlhxLBZ3BAF";
const NSString* SECRET_KEY = @"68e5d0acfd1ef99858e2a3815f0e8eec";
const NSString* APP_ID = @"11026313";

@interface ChatViewController ()

@property WebViewJavascriptBridge* bridge;
@property (strong, nonatomic) BDSEventManager *asrEventManager;
@property(nonatomic, assign) BOOL continueToVR;
@property(nonatomic, strong) NSFileHandle *fileHandler;
@property(nonatomic, strong) BDRecognizerViewController *recognizerViewController;
@property(nonatomic, assign) TBDVoiceRecognitionOfflineEngineType curOfflineEngineType;
@property(nonatomic, strong) NSTimer *longPressTimer;
@property(nonatomic, assign) BOOL longPressFlag;
@property(nonatomic, assign) BOOL touchUpFlag;
@property(nonatomic, assign) BOOL longSpeechFlag;

@end

@implementation ChatViewController{
    NSString *htmlLogin;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = YES;
    self.asrEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
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
    //将webview与webviewJavascriptBridge关联
    _bridge = [WebViewJavascriptBridge bridgeForWebView:self.webView webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
    }];
    
    [_bridge registerHandler:@"startRecord" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"js传过来的参数---->  %@",data);
        //按到发送语音按钮了
        [self recognizeVoice];
        //[self longSpeechRecognition];
        responseCallback(@"谁在呼喊");
    }];
    
    [_bridge registerHandler:@"stopRecord" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"js传过来的参数---->  %@",data);
        self.touchUpFlag = YES;
        if (self.longPressFlag) {
            [self.asrEventManager sendCommand:BDS_ASR_CMD_STOP];
        }
        responseCallback(@"发送结束");
    }];
    
    //添加静态页面到本地
    [self.view addSubview:self.webView];
    //[self.view addSubview:self.activityIndicator];
    [self loadUrl];
}

//语音识别方法
- (void)recognizeVoice
{
    self.touchUpFlag = NO;
    self.longPressFlag = NO;
    //    self.longPressTimer = [NSTimer timerWithTimeInterval:0.5
    //                                                  target:self
    //                                                selector:@selector(longPressTimerTriggered) userInfo:nil repeats:NO];
    //[[NSRunLoop currentRunLoop] addTimer:self.longPressTimer forMode:NSRunLoopCommonModes];
    [self longPressTimerTriggered];
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_LONG_SPEECH];
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_NEED_CACHE_AUDIO];
    [self.asrEventManager setParameter:@"" forKey:BDS_ASR_OFFLINE_ENGINE_TRIGGERED_WAKEUP_WORD];
    [self voiceRecogButtonHelper];
}

- (void)longPressTimerTriggered
{
    if (!self.touchUpFlag) {
        self.longPressFlag = YES;
        [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_VAD_ENABLE_LONG_PRESS];
    }
    [self.longPressTimer invalidate];
}

//长语音识别
- (void)longSpeechRecognition
{
    self.longSpeechFlag = YES;
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_NEED_CACHE_AUDIO];
    [self.asrEventManager setParameter:@"" forKey:BDS_ASR_OFFLINE_ENGINE_TRIGGERED_WAKEUP_WORD];
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_LONG_SPEECH];
    // 长语音请务必开启本地VAD
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_LOCAL_VAD];
    [self voiceRecogButtonHelper];
}

//音频流识别
- (void)audioStreamRecognition
{
    //[self cleanLogUI];
//    AudioInputStream *stream = [[AudioInputStream alloc] init];
//    [self.asrEventManager setParameter:stream forKey:BDS_ASR_AUDIO_INPUT_STREAM];
//    [self.asrEventManager setParameter:@"" forKey:BDS_ASR_AUDIO_FILE_PATH];
//    [self.asrEventManager setDelegate:self];
//    [self.asrEventManager sendCommand:BDS_ASR_CMD_START];
    //[self onInitializing];
}
//加载离线引擎
- (void)loadOfflineEngine
{
    //[self cleanLogUI];
    [self configOfflineClient];
    [self.asrEventManager sendCommand:BDS_ASR_CMD_LOAD_ENGINE];
}
//卸载离线引擎
- (void)unLoadOfflineEngine
{
    [self.asrEventManager sendCommand:BDS_ASR_CMD_UNLOAD_ENGINE];
}

//文件识别
- (void)fileRecognition
{
    //[self cleanLogUI];
    NSString* testFile = [[NSBundle mainBundle] pathForResource:@"16k_test" ofType:@"pcm"];
    [self.asrEventManager setParameter:testFile forKey:BDS_ASR_AUDIO_FILE_PATH];
    [self.asrEventManager setDelegate:self];
    [self.asrEventManager sendCommand:BDS_ASR_CMD_START];
}

//语音识别回调接口
- (void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj {
    switch (workStatus) {
        case EVoiceRecognitionClientWorkStatusStartWorkIng: {
            //NSDictionary *logDic = [self parseLogToDic:aObj];
            //NSLog(@"%@",logDic);
            NSLog(@"EVoiceRecognitionClientWorkStatusStartWorkIng:识别工作开始，开始采集及处理数据");
            
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusNewRecordData: {
            [self.fileHandler writeData:(NSData *)aObj];
            NSLog(@"EVoiceRecognitionClientWorkStatusNewRecordData:录音数据回调");
            NSLog(@"%@",aObj);
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusStart: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusStart:检测到用户开始说话");
            NSLog(@"%@",aObj);
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusEnd: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusEnd:本地声音采集结束，等待识别结果返回并结束录音");
            NSLog(@"%@",aObj);
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusFlushData: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusFlushData:连续上屏");
            //[self getDescriptionForDic:aObj];
            NSLog(@"%@",aObj);
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusFinish: {
            if (aObj) {
                NSString *text = [self getDescriptionForDic:aObj];
                NSLog(@"语音识别结果  %@",text);
            }
            if (!self.longSpeechFlag) {
                //[self onEnd];
                self.longSpeechFlag = NO;
            }
            NSLog(@"EVoiceRecognitionClientWorkStatusFinish:语音识别功能完成，服务器返回正确结果");
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusMeterLevel: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusMeterLevel:当前音量回调");
            NSLog(@"%@",aObj);
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusCancel: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusCancel:用户取消");
            NSLog(@"%@",aObj);
            self.longSpeechFlag = NO;
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusError: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusError:发生错误");
            NSLog(@"%@",aObj);
            self.longSpeechFlag = NO;
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusLoaded: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusLoaded:离线引擎加载完成");
            NSLog(@"%@",aObj);
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusUnLoaded: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusUnLoaded:离线引擎卸载完成");
            NSLog(@"%@",aObj);
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusChunkThirdData: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusChunkThirdData:识别结果中的第三方数据");
            NSLog(@"%@",aObj);
            //(unsigned long)[(NSData *)aObj length];
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusChunkNlu: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusChunkNlu:识别结果中的语义结果");
            NSLog(@"%@",aObj);
            NSString *nlu = [[NSString alloc] initWithData:(NSData *)aObj encoding:NSUTF8StringEncoding];
            NSLog(@"%@", nlu);
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusChunkEnd: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusChunkEnd:识别过程结束");
            NSLog(@"%@",aObj);
            if (!self.longSpeechFlag) {
                self.longSpeechFlag = NO;
            }
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusFeedback: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusFeedback:识别过程反馈的打点数据");
            NSLog(@"%@",aObj);
            NSDictionary *logDic = [self parseLogToDic:aObj];
            //[self printLogTextView:[NSString stringWithFormat:@"CALLBACK Feedback: %@\n", logDic]];
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusRecorderEnd: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusRecorderEnd:录音机关闭，页面跳转需检测此时间，规避状态条 (iOS)");
            NSLog(@"%@",aObj);
            break;
        }
            
        case EVoiceRecognitionClientWorkStatusLongSpeechEnd: {
            
            NSLog(@"EVoiceRecognitionClientWorkStatusLongSpeechEnd:长语音结束状态");
            NSLog(@"%@",aObj);
            self.longSpeechFlag = NO;
            break;
        }
            
        default:
            break;
    }
}

- (NSDictionary *)parseLogToDic:(NSString *)logString
{
    NSArray *tmp = NULL;
    NSMutableDictionary *logDic = [[NSMutableDictionary alloc] initWithCapacity:3];
    NSArray *items = [logString componentsSeparatedByString:@"&"];
    for (NSString *item in items) {
        tmp = [item componentsSeparatedByString:@"="];
        if (tmp.count == 2) {
            [logDic setObject:tmp.lastObject forKey:tmp.firstObject];
        }
    }
    return logDic;
}

#pragma mark - BDRecognizerViewDelegate

- (void)onRecordDataArrived:(NSData *)recordData sampleRate:(int)sampleRate
{
    [self.fileHandler writeData:(NSData *)recordData];
}

- (void)onEndWithViews:(BDRecognizerViewController *)aBDRecognizerViewController withResult:(id)aResult
{
    if (aResult) {
        //self.resultTextView.text = [self getDescriptionForDic:aResult];
    }
    [self.asrEventManager setDelegate:self];
}

#pragma mark - Private: Configuration

- (void)configVoiceRecognitionClient {
    //设置DEBUG_LOG的级别
    [self.asrEventManager setParameter:@(EVRDebugLogLevelTrace) forKey:BDS_ASR_DEBUG_LOG_LEVEL];
    //配置API_KEY 和 SECRET_KEY 和 APP_ID,参数配置：在线身份验证
    [self.asrEventManager setParameter:@[API_KEY, SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
    //设置APPID
    [self.asrEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
    //配置端点检测（二选一）
    [self configModelVAD];//检测更加精准，抗噪能力强，响应速度较慢
    //[self configDNNMFE];//提供基础检测功能，性能高，响应速度快
    
    //     [self.asrEventManager setParameter:@"15361" forKey:BDS_ASR_PRODUCT_ID];
    // ---- 语义与标点 -----
    [self enableNLU];
    //    [self enablePunctuation];
    // ------------------------
}


- (void) enableNLU {
    // ---- 开启语义理解 -----
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_NLU];
    [self.asrEventManager setParameter:@"1536" forKey:BDS_ASR_PRODUCT_ID];
}

- (void) enablePunctuation {
    // ---- 开启标点输出 -----
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_DISABLE_PUNCTUATION];
    // 普通话标点
    //    [self.asrEventManager setParameter:@"1537" forKey:BDS_ASR_PRODUCT_ID];
    // 英文标点
    [self.asrEventManager setParameter:@"1737" forKey:BDS_ASR_PRODUCT_ID];
    
}


- (void)configModelVAD {
    //NSString *modelVAD_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
    //[self.asrEventManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
    //[self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
    
    NSString *modelVAD_filepath=[[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
    
    [self.asrEventManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
    
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
    
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_NLU];
    
    [self.asrEventManager setParameter:@"15361" forKey:BDS_ASR_PRODUCT_ID];
}

- (void)configDNNMFE {
    NSString *mfe_dnn_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_mfe_dnn" ofType:@"dat"];
    [self.asrEventManager setParameter:mfe_dnn_filepath forKey:BDS_ASR_MFE_DNN_DAT_FILE];
    NSString *cmvn_dnn_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_mfe_cmvn" ofType:@"dat"];
    [self.asrEventManager setParameter:cmvn_dnn_filepath forKey:BDS_ASR_MFE_CMVN_DAT_FILE];
    
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_MODEL_VAD];
    // MFE支持自定义静音时长
    //    [self.asrEventManager setParameter:@(500.f) forKey:BDS_ASR_MFE_MAX_SPEECH_PAUSE];
    //    [self.asrEventManager setParameter:@(500.f) forKey:BDS_ASR_MFE_MAX_WAIT_DURATION];
}


- (void)voiceRecogButtonHelper
{
    //    [self configFileHandler];
    [self.asrEventManager setDelegate:self];
    [self.asrEventManager setParameter:nil forKey:BDS_ASR_AUDIO_FILE_PATH];
    [self.asrEventManager setParameter:nil forKey:BDS_ASR_AUDIO_INPUT_STREAM];
    [self.asrEventManager sendCommand:BDS_ASR_CMD_START];
    //[self onInitializing];
}
- (void)configOfflineClient {
    
    // 离线仅可识别自定义语法规则下的词
    NSString* gramm_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_gramm" ofType:@"dat"];;
    NSString* lm_filepath = [[NSBundle mainBundle] pathForResource:@"bds_easr_basic_model" ofType:@"dat"];;
    NSString* wakeup_words_filepath = [[NSBundle mainBundle] pathForResource:@"WakeUp" ofType:@"bin"];;
    NSLog(@"唤醒文件的地址:  %@",wakeup_words_filepath);
    [self.asrEventManager setDelegate:self];
    [self.asrEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
    [self.asrEventManager setParameter:lm_filepath forKey:BDS_ASR_OFFLINE_ENGINE_DAT_FILE_PATH];
    // 请在 (官网)[http://speech.baidu.com/asr] 参考模板定义语法，下载语法文件后，替换BDS_ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH参数
    [self.asrEventManager setParameter:gramm_filepath forKey:BDS_ASR_OFFLINE_ENGINE_GRAMMER_FILE_PATH];
    [self.asrEventManager setParameter:wakeup_words_filepath forKey:BDS_ASR_OFFLINE_ENGINE_WAKEUP_WORDS_FILE_PATH];
    
}

- (void)configRecognizerViewController {
    
}

- (void)configFileHandler {
    //self.fileHandler = [self createFileHandleWithName:@"recoder.pcm" isAppend:NO];
}







//键盘弹出后将视图向上移动
-(void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary *info = [note userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    //目标视图webview
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

- (void)loadUrl
{
    //第二步：加载服务器url，实现代理方法。-----注意点拦截url解决webview加载本地连接不显示问题
    htmlLogin = [[NSBundle mainBundle] pathForResource:@"chart"ofType:@"html"inDirectory:@"assets/"];
    NSLog(@"聊天%@",htmlLogin);
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

- (NSString *)getDescriptionForDic:(NSDictionary *)dic {
    if (dic) {
        return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic
                                                                              options:NSJSONWritingPrettyPrinted
                                                                                error:nil] encoding:NSUTF8StringEncoding];
    }
    return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
