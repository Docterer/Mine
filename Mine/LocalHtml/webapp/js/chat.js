/**
 * Created by sophieChen on 18/03/09.
 */

var input_val = {},
    audioBox = true;//用来判断是否在对话中加入小icon的判断量；

function chat(element,imgSrc,callback){
    var $user = element,$textContent;
    if(typeof callback === 'function'){
        $textContent = callback();
    }else {
        $textContent = callback;
    }
    if( typeof ($textContent) === "string"){
        $textContent = $textContent.replace(/[<div>]/g,"");
        $textContent = $textContent.replace(/[<\/div>]/g,"");
        $textContent = $textContent.replace(/\ +/g, ""); //去掉空格
        $textContent = $textContent.replace(/[&nbsp;]/g, "");  //去掉空格
        $textContent = $textContent.replace(/[\r\n]/g, ""); //去掉回车换行
        $textContent = $textContent.replace(/[\n]/g, ""); //去掉换行
        $textContent = $textContent.replace(/[r]/g, ""); //去掉回车
    }

    var $box = $('.bubbleDiv');
    var inset_hint,hint_str = "";
    var $boxHeight = 0;

    function boxheight(box){
        var i,boxHeight = 0,add;
        for(i=0;i<box.children('div').length;i++){
            boxHeight += $(box.children('div')[i]).height();
        }
        return boxHeight;
    }
    if($user === "leftBubble"){
        $boxHeight =  boxheight($box);
        $box.append(createdoct(imgSrc,$textContent)).animate({"scrollTop":$boxHeight }, 300);
        if(input_val.length > 0){
            for (var i = 0; i < input_val.length; i++){
                hint_str +='<span class="re-li">' + input_val[i] + '</span>'
            }
            var recueHeight = $('.bubbleItem.right-input:last').height();
            // 因为有提示文字，所以需要我们的左侧框框距离远点来保证能够清晰的显示提示的文字；否则右侧提示是绝对定位
            $('.bubbleItem:last').css('marginTop','1.2rem');
            inset_hint = '<div class="re-cue" style="margin-top:'+ recueHeight + 'px;">' + hint_str + '</div>';
        }
        $('.bubbleDiv .right-input:last').append(inset_hint);
    }else if($user === "rightBubble"){
        $boxHeight =  boxheight($box);
        $box.append(createuser(imgSrc,$textContent)).animate({"scrollTop":$boxHeight}, 300);
    }else if($user === "rightBubble audioBox"){
        $boxHeight =  boxheight($box);
        $box.append(createuseraudio(imgSrc,$textContent)).animate({"scrollTop":$boxHeight}, 300);
        if(audioBox){
            $('.right-input:last').append(audioBox);
        }
    }else{
        console.log("请在函数中传入必须的参数");
    }
}
// 图片和返回的值
function createdoct(imgSrc, $doctextContent ) {
    var $imgSrc = imgSrc;
    var block;

    if($doctextContent === ''|| $doctextContent === null){
        alert('没有正确的值返回');
        return;
    }

    block = '<div class="bubbleItem">' +
            '<div class="doctor-head">' +
            '<img src="'+ imgSrc +'" alt="doctor"/>' +
            '</div>' +
            '<span class="bubble leftBubble">' + $doctextContent.question_name +
            '<a href="../personalMsg.html">诊断结果</a> ' +
            '<span class="topLevel"></span></span>' +
            '</div>';
            input_val = $doctextContent.input_parse;

    ajax_Txt($doctextContent.question_name);
    // 每次创建一个音源进行播放
    return block;
};

function createuser(imgSrc,$textContent){
    var $textContent = $textContent;
    var block;
    if($textContent === ''|| $textContent === null){
        alert('亲！别太着急，先说点什么吧～');
        return;
    }
    block = '<div class="bubbleItem right-input clearfix">' +
                '<span class="bubble rightBubble">' + $textContent + '<span class="topLevel"></span></span>' +
                '<div class="doctor-head rightbox">' +
                '<img src="'+ imgSrc +'" alt="user"/>' +
                '</div>' +
                '</div>';
    return block;

};

function createuseraudio(imgSrc,$textContent){
    var $textContent = $textContent;
    var block;
    if($textContent === ''|| $textContent === null){
        alert('亲！别太着急，先说点什么吧～');
        audioBox = false;
        return;
    }
    block = '<div class="bubbleItem right-input clearfix">' +
                '<span class="bubble rightBubble">' + $textContent  +  '<span class="leftLevel"></span>' +'<span class="topLevel"></span></span>' +
                '<div class="doctor-head rightbox">' +
                '<img src="'+ imgSrc +'" alt="user"/>' +
                '</div>' +
                '</div>';
    return block;

};

function _base64ToArrayBuffer(base64) {
    var binary_string =  window.atob(base64);
    var len = binary_string.length;
    var bytes = new Uint8Array( len );
    for (var i = 0; i < len; i++)        {
        bytes[i] = binary_string.charCodeAt(i);
    }
    return bytes.buffer;
}
// 发送给文字转base64的ajax
function ajax_Txt(mydata){
    var json = {
        "txtData":mydata
    };
    console.log( '发出给翻译后台的文字：'+ json.txtData);
    $.ajax({
        type: "POST",
        url: "https://51icare.com:8000/DemoService/PostTxt/",
        contentType: "application/json; charset=utf-8",
        data: JSON.stringify(json),
        dataType: "json",
        success: function (message) {
            var arraybuffer =  _base64ToArrayBuffer(message),
                source;
            source = audioCtx.createBufferSource();
            audioCtx.decodeAudioData(arraybuffer, function(buffer){
                    source.buffer = buffer;
                    source.connect(audioCtx.destination);
                    source.start(0);
                    },
                function(e){"Error with decoding audio data" + e.err});
        },
        error: function (message) {
            $("#request-process-patent").html("提交数据失败！");
        }
    });
}

