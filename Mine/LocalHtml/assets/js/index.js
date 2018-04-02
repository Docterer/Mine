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
	//注册提供给OC网络状态实时监控的方法以调用
// bridge.registerHandler("openPage", function(data, responseCallback) {
// 		  //data是OC返回给JS的值，responseCallback是js收到值后通知OC的方法
// 		  		window.location.href = "chart01.html";
//             responseCallback(data);
//     });
   });