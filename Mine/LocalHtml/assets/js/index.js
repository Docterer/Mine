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
	//js提供给原生调用的唤醒机器人效果
    bridge.registerHandler("wakeup", function(data, responseCallback) {
        $("#robit").attr("src","images/index-robit-wakeup.gif");
        console.log("js起来起来:"+data);
    });
   });