//
//  linkmeEshare.h
//  linkme
//
//  Created by 云联科技 on 2018/5/30.
//

#import <Cordova/CDVPlugin.h>

@interface esharePlugin : CDVPlugin

//展示设备列表
- (void)showEshareDevices:(CDVInvokedUrlCommand *)command;
//开始镜像
- (void)startMirror:(CDVInvokedUrlCommand *)command;
//启动文件传送
- (void)startFileTrans:(CDVInvokedUrlCommand *)command;
//断开设备连接
- (void)disconnectDevice:(dispatch_block_t)successBlock;
//通过eshare打开文件
- (void)openFileInEshare:(CDVInvokedUrlCommand *)command;

@end
