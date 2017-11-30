window.AlipayJSBridge || (function () {

    var iframe = null;

    function renderIframe() {
        if (iframe) return;
        try {
            iframe = document.createElement("iframe");
            iframe.id = "__AlipayJSBridgeIframe";
            iframe.style.display = "none";
            document.documentElement.appendChild(iframe);
        } catch (e) {

        }
    }

    function onDOMReady(callback) {
        var readyRE = /complete|loaded|interactive/;
        if (readyRE.test(document.readyState)) {
            setTimeout(function() {
                       callback();
                       }, 1);
        } else {
            document.defaultView.addEventListener('DOMContentLoaded', function () {
                callback();
            }, false);
        }
    }

    var callbackPoll = {};

    var sendMessageQueue = [];
    var receiveMessageQueue = [];

    var H5_PLUGIN_BASE_URL = "jsplugin://www.alipay.com?plugins=";
    var H5_PLUGIN_CALLBACK_UNIQUE_ID = 0;
    var H5_PLUGIN_CALLBACK_PREFIX = "h5dp_callback_id_";
    var H5_PLUGIN_STACK = [];

    var JSAPI = {
        
        call: function (func, param, callback) {
            renderIframe();
            if (!iframe) return;
            //
            if ('string' !== typeof func) {
                return;
            }

            if ('function' === typeof param) {
                callback = param;
                param = null;
            } else if (typeof param !== 'object') {
                param = null;
            }

            var callbackId = func + '_' + new Date().getTime() + (Math.random());
            if ('function' === typeof callback) {
                callbackPoll[callbackId] = callback;
            }

            if (param && param.callbackId) {
                func = {
                    responseId: param.callbackId,
                    responseData: param
                };
                delete param.callbackId;
            } else {
                func = {
                    handlerName: func,
                    data: param
                };
                func.callbackId = '' + callbackId;
            }

//            console.log('bridge.call: ' + JSON.stringify(func));
            sendMessageQueue.push(func);
            iframe.src = "alipaybridge://dispatch_message";
        },

        trigger: function (name, data) {
//            console.log('bridge.trigger ' + name);
            if (name) {
                var triggerEvent = function (name, data) {
                    var callbackId;
                    if (data && data.callbackId) {
                        callbackId = data.callbackId;
                        data.callbackId = null;
                    }
                    var evt = document.createEvent("Events");
                    evt.initEvent(name, false, true);
                    if (data) {
                        if (data.__pull__) {
                            delete data.__pull__;
                            for (var k in data) {
                                evt[k] = data[k];
                            }
                        } else {
                            evt.data = data;
                        }
                    }
                    var canceled = !document.dispatchEvent(evt);
                    if (callbackId) {
                        var callbackData = {};
                        callbackData.callbackId = callbackId;
                        callbackData[name + 'EventCanceled'] = canceled;
                        JSAPI.call('__nofunc__', callbackData);
                    }
                };
                setTimeout(function () {
                    triggerEvent(name, data);
                }, 1);
            }
        },

        
        _invokeJS: function (resp) {
//            console.log('bridge._invokeJS: ' + resp);
            resp = JSON.parse(resp);
            if (resp.responseId) {
                var func = callbackPoll[resp.responseId];
                if (!(typeof resp.keepCallback == 'boolean' && resp.keepCallback)) {
                    delete callbackPoll[resp.responseId];
                }

                if ('function' === typeof func) {
                    setTimeout(function () {
                        func(resp.responseData);
                    }, 1);
                }
            } else if (resp.handlerName) {

                if (resp.handlerName == "H5DynamicPluginCallback") {
                    if (callbackPoll[resp.data.callbackId]) {
                        var func = callbackPoll[resp.data.callbackId];
                        if ('function' === typeof func) {
                            setTimeout(function () {
                                func();
                            }, 1);
                        }
                    }

                } else {
                    if (resp.callbackId) {
                        resp.data = resp.data || {};
                        resp.data.callbackId = resp.callbackId;
                    }
                    JSAPI.trigger(resp.handlerName, resp.data);
                }

            }
        },

        // ***********************************************

        _handleMessageFromObjC: function (message) {
            if (receiveMessageQueue&&!window.AlipayJSBridge) {
                receiveMessageQueue.push(message);
            } else {
                JSAPI._invokeJS(message);
            }
        },

        _fetchQueue: function () {
            var messageQueueString = typeof [].toJSON == 'function' ? sendMessageQueue.toJSON() : JSON.stringify(sendMessageQueue);
            if (typeof messageQueueString != 'string') {
                messageQueueString = JSON.stringify(sendMessageQueue);
            }
            sendMessageQueue = [];
            return messageQueueString;
        },

        loadPlugin: function (plugins, callback) {
            // only iOS platform
            if (navigator.userAgent.indexOf('iPhone') === -1 &&
                navigator.userAgent.indexOf('iPad') === -1 &&
                navigator.userAgent.indexOf('iPod') === -1) {
                return;
            }

            H5_PLUGIN_STACK.push({
                'plugins': plugins,
                'callback': callback
            });

            if (!window.H5_PLUGIN_LOADER) {
                window.H5_PLUGIN_LOADER = setInterval(function () {
                    var pluginsConfig = H5_PLUGIN_STACK.shift();
                    if (typeof pluginsConfig != 'undefined' && typeof pluginsConfig.plugins != 'undefined') {
                        var plugins = pluginsConfig.plugins;
                        var callback = pluginsConfig.callback;
                        var pluginArray = [];
                        if (Object.prototype.toString.call(plugins) === '[object Array]') {
                            for (var i = 0, l = plugins.length; i < l; i++) {
                                pluginArray.push(plugins[i]);
                            }
                        } else if (typeof plugins === 'string') {
                            pluginArray.push(plugins);
                        }

                        if (callback && typeof callback == 'function') {
                            var callbackId = H5_PLUGIN_CALLBACK_PREFIX + H5_PLUGIN_CALLBACK_UNIQUE_ID++;
                            callbackPoll[callbackId] = callback;
                            document.location.href = H5_PLUGIN_BASE_URL + encodeURIComponent(pluginArray.join(',')) +
                                '&callbackId=' + callbackId;
                        } else {
                            document.location.href = H5_PLUGIN_BASE_URL + encodeURIComponent(pluginArray.join(','));
                        }
                    } else {
                        window.clearInterval(window.H5_PLUGIN_LOADER);
                        window.H5_PLUGIN_LOADER = undefined;
                    }
                }, 50);
            }
        }
    };

    // ***********************************************

    JSAPI.init = function () {
        // dont call me any more
        JSAPI.init = null;

        "JS_BRIDGE_JS_***_REPLACE_STRING_***_SJ_EGDIRB_SJ";
        
        var readyEvent = document.createEvent('Events');
        readyEvent.initEvent('AlipayJSBridgeReady', false, false);

        var docAddEventListener = document.addEventListener;
        document.addEventListener = function (name, func) {
            if (name === readyEvent.type) {
                setTimeout(function () {
                    func(readyEvent);
                }, 1);
            } else {
                docAddEventListener.apply(document, arguments);
            }
        };

        document.dispatchEvent(readyEvent);

        var receivedMessages = receiveMessageQueue;
        receiveMessageQueue = null;
        for (var i = 0; i < receivedMessages.length; i++) {
            JSAPI._invokeJS(receivedMessages[i]);
        }
    };

    window.AlipayJSBridge = JSAPI;

    JSAPI.startupParams=window.ALIPAYH5STARTUPPARAMS||{};
    //window.ALIPAYH5STARTUPPARAMS=null;
                          
    onDOMReady(JSAPI.init);
    onDOMReady(function(){
               var jsArray = window.ALIPAYH5DYNAMICSCRIPT;
               for (var i in jsArray) {
               var jsSrc = jsArray[i];
                   if (jsSrc&&/^([\w.+-]+:)(?:\/\/(?:[^\/?#]*@|)([^\/?#:]*)(?::(\d+)|)|)/.test(jsSrc)){
                        var script,head = document.head || document.documentElement;
                        script=document.createElement("script");
                        script.async = true;
                        script.charset="UTF-8";
                        script.src = jsSrc;
                        head.insertBefore(script,head.firstChild);
                   };
               }
    });
})();
