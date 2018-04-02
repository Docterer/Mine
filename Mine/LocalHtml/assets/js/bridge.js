function connectWebViewJavascriptBridge(callback) {
                       if (window.WebViewJavascriptBridge) {
                           callback(WebViewJavascriptBridge)
                       } else {
                           document.addEventListener(
                               'WebViewJavascriptBridgeReady'
                               , function() {
                                   callback(WebViewJavascriptBridge)
                               },
                               false
                           );
                       }
                   }
//注册回调函数，第一次连接时调用 初始化函数
connectWebViewJavascriptBridge(function(bridge) {
       bridge.init(function(message, responseCallback) {
          console.log('JS got a message', message);
	    var data = {
	        'Javascript Responds': '测试中文!'
	    };
	    console.log('JS responding with', data);
	        responseCallback(data);
	   	});
  });