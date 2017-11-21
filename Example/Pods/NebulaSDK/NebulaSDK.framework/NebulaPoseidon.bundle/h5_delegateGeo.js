"use strict";
(function (window) {
    function call() {
        var a = arguments,
                fn = function () {
                    window.AlipayJSBridge.call.apply(null, a);
                };

        window.AlipayJSBridge ? fn() : document.addEventListener('AlipayJSBridgeReady', fn, false);
    }
    window.navigator.geolocation.getCurrentPosition = function (cb) {
        call('getLocation', function (rtv) {
            var pos = {
                coords: {
                    accuracy: 50,
                    altitude: null,
                    altitudeAccuracy: null,
                    heading: null,
                    latitude: null,
                    longitude: null,
                    speed: null
                },
                timestamp: (+new Date())
            };
            for (var k in rtv) {
                if (rtv.hasOwnProperty(k)) {
                    pos.coords[k] = rtv[k];
                }
            }
            cb && cb(pos);
        });
    };
})(window);