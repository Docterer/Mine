$(document).ready(function(){

	$('#voice-btn').on('click',function(){
		showVoicePanel();
	});

	$('#keyboard-btn').click(function(){
		showKeyboardPanel();
	});

	$('#send-btn').on('click',function(){
		var userSendMessage = $('#user-input-message').val();
		if(userSendMessage != '') {
			$('#user-input-message').val('');
			addUserRequest(userSendMessage);
			 window.WebViewJavascriptBridge.callHandler(
                        'sendToTuLin'
                        , {'param': userSendMessage }
                        , function(responseData) {
                                var toastData = responseData;
                                console.error("調用成功"+responseData);
                        }
                     );
		}
	});
});





//init start
mui.init({
  gestureConfig:{
    longtap: true, //默认为false
    release:true,
    swipe: true, //默认为true
    hold:true
   }
});
//init end

var data = "nothing";
var btnElem=document.getElementById("recordVoice");//获取ID
var posStart = 0;//初始化起点坐标
var posEnd = 0;//初始化终点坐标
var posMove = 0;//初始化滑动坐标
console.log(screen);
function initEvent() {
    btnElem.addEventListener("touchstart", function(event) {
        event.preventDefault();//阻止浏览器默认行为
        posStart = 0;
        posStart = event.touches[0].pageY;//获取起点坐标
        btnElem.innerText = '松开 完成';
        btnElem.style.backgroundColor = "red";
        btnElem.style.color = "white";
        $("#hold").removeClass("hide");
        say();
        study();
        console.log("正在长按" );
        //调用原生停止机器人讲话方法
//      window.WebViewJavascriptBridge.callHandler(
//                  'stopRobotSpeeking'
//                  , {'param': data }
//                  , function(responseData) {
//                          var toastData = responseData;
//                          console.error("机器人停止讲话調用成功"+responseData);
//                  }
//       );
         //调用原生开始录音方法
         window.WebViewJavascriptBridge.callHandler(
            'startRecord'
            , {'param': '正在长按'}
            , function(responseData) {
                    //调用原生默认的处理Handle——弹框
                    var toastData = responseData;
                    console.error("調用成功"+responseData);
            }
         );
    });
    btnElem.addEventListener("touchmove", function(event) {
        event.preventDefault();//阻止浏览器默认行为
        posMove = 0;
        posMove = event.targetTouches[0].pageY;//获取滑动实时坐标
        if(posStart - posMove < 150){
            btnElem.innerText = '松开 结束';
            $("#hold").removeClass("hide");
            $("#cancel").addClass("hide");
        }else{
            $("#hold").addClass("hide");
            $("#cancel").removeClass("hide");
            btnElem.innerText = '松开手指，取消发送';

        }
    });
    btnElem.addEventListener("touchend", function(event) {
        event.preventDefault();
        posEnd = 0;
        posEnd = event.changedTouches[0].pageY;//获取终点坐标
        btnElem.innerText = '按住 说话';
        btnElem.style.backgroundColor = "";
                        btnElem.style.color = "black";
        $("#hold").addClass("hide");
        $("#cancel").addClass("hide");
        if(posStart - posEnd < 150 ){
            console.log("发送成功");
            stopSay();
            search();
            window.WebViewJavascriptBridge.callHandler(
                    'stopRecord'
                    , {'param': data }
                    , function(responseData) {
                         var toastData = responseData;
                         console.error("調用成功"+responseData);
                    }
            );
        }else{
            console.log("取消发送");
            stopSay();
            sleep();
            //调用原生取消录音
         	window.WebViewJavascriptBridge.callHandler(
                 'cancelRecord'
                         , {'param': data }
                         , function(responseData) {
                              var toastData = responseData;
                               console.error("調用成功"+responseData);
                         }
             );
        };
    });
};
initEvent();

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
       // 第一连接时初始化bridage
        connectWebViewJavascriptBridge(function(bridge) {
            bridge.init(function(message, responseCallback) {
                console.log('JS got a message', message);
                var data = {
                    'Javascript Responds': '测试中文!'
                };
                console.log('JS responding with', data);
                responseCallback(data);
            });
            //显示用户聊天消息
            bridge.registerHandler("showMyMsg", function(data, responseCallback) {
                if(data != null && data != undefined){
                		//var arr = JSON.parse(data);
                		//data = arr.results_recognition[0];
                		//alert("机器返回的识别结果:"+data);
                     addUserRequest(data);
                     responseCallback(data);
//                     addRobotResponse("机器人说："+data);
                }

            });
            //显示机器人聊天消息
            bridge.registerHandler("showBobotMsg", function(data, responseCallback) {
                            if(data != null && data != undefined){
//                                 addUserRequest(data);
								//data = JSON.parse(data);
                                 addRobotResponse(data);
                            }else{
                                addRobotResponse("你说啥？俺没听到!");
                            }

                        });
            //开始机器人说话效果展示
            bridge.registerHandler("robotSay", function(data, responseCallback) {
                console.log("这是原生传的入参:"+data);
                say();
                smile();
                responseCallback("js:机器人说话了");
             });

            //停止机器人说话效果展示
            bridge.registerHandler("robotStop", function(data, responseCallback) {
                 console.log("这是原生传的入参:"+data);
                 sleep();
                 stopSay();
                 responseCallback("js:机器人停止说话");
             });

             //用户输入语音音量效果展示
            bridge.registerHandler("updateVolume", function(data, responseCallback) {
            		  //alert("这是原生传的音量入参:"+data);
                  console.log("这是原生传的音量入参:"+data);
                  var volumeLevel = 1;
                  if(data != 0 && data != null && data != undefined){
                      volumeLevel = Math.ceil(data/5);
                  }
                  if(volumeLevel > 7){
                    volumeLevel = 7;
                  }
                  volume(volumeLevel);
                  responseCallback("js:音量效果展示完毕，音量等级:"+volumeLevel);
             });      
        })

function showKeyboardPanel() {
	$('#keyboard-panel').show();
	$('#voice-panel').hide();
}

function showVoicePanel() {
	$('#voice-panel').show();
	$('#keyboard-panel').hide();
}

//聊天页面 机器人-静止
function sleep() {
	$('#robit-img').attr('src','images/sm-robit.png');
}
//聊天页面 机器人-说话
function smile() {
	$('#robit-img').attr('src','images/smile.gif');
}
//聊天页面 机器人-查找
function search() {
	$('#robit-img').attr('src','images/search.gif');
}
//聊天页面 机器人-学习
function study() {
	$('#robit-img').attr('src','images/study.gif');
}
//聊天页面 机器人-再见
function goodbye() {
	$('#robit-img').attr('src','images/goodbye.gif');
}
//聊天页面显示声波
function say() {
	$('#shengbo-img').attr('src','images/bwt.gif');
}
//聊天页面隐藏声波
function stopSay() {
	$('#shengbo-img').attr('src','images/bwt.png');
}

//聊天页面 语音音量
function volume(params) {
	$('#volume-img').attr('src','images/volume'+params+'.png');
}


function addUserRequest(data) {
	var request = '<li>'
				+'<div class="main">'
				+	'<img class="avatar right" width="42" height="42" src="images/head2.png">'
				+    '<div class="text-right">' + data + '</div>'
				+'</div>'
				+'</li>';
	$("#ul-message").append(request);
	var a = $('div.m-message');
    a.scrollTop(a[0].scrollHeight);
}

function addRobotResponse(data) {
	var response = '<li>'
				+'<div class="main">'
				+	'<img class="avatar" width="42" height="42" src="images/head1.png">'
				+    '<div class="text">' + data + '</div>'
				+'</div>'
				+'</li>';
	$("#ul-message").append(response);
	var a = $('div.m-message');
    a.scrollTop(a[0].scrollHeight);
    sleep();
}
function clear(){
    $("#ul-message").empty();
}