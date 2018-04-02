//
//  ChatViewController.h
//  Mine
//
//  Created by 单怡然 on 2018/4/2.
//  Copyright © 2018年 单怡然. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebViewJavascriptBridge.h"

@interface ChatViewController : UIViewController<UIWebViewDelegate>
@property (nonatomic, strong) UIWebView* webView;
@property(nonatomic,strong) NSString *url;

@end
