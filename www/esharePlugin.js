var exec = require('cordova/exec');

exports.coolMethod = function (success,error,arg0) {
    exec(success, error, 'esharePlugin', 'showEshareDevices', arg0);
};

exports.transMethod = function (success,error,arg0) {
    exec(success, error, 'esharePlugin', 'startFileTrans', arg0);
};

exports.mirrorMethod = function (success,error,arg0) {
    exec(success, error, 'esharePlugin', 'startMirror', arg0);
};

exports.shareDocMethod = function (success,error,arg0) {
	exec(success,error,'esharePlugin','openFileInEshare', arg0);
}