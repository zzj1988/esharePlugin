//
//  linkmeEshare.m
//  linkme
//
//  Created by 云联科技 on 2018/5/30.
//

#import "esharePlugin.h"
#import <EShare/EShare.h>

@interface esharePlugin ()

@property (nonatomic,strong)ESDevice *connectedDevice;
@property (strong, nonatomic)UIImageView *screenImg;
@property (strong, nonatomic)NSString *transHttp;
@property (strong, nonatomic)ESHttpManage *httpManager;

@end

@implementation esharePlugin

#pragma mark - 棒子功能
//显示棒子列表
- (void)showEshareDevices:(CDVInvokedUrlCommand *)command
{
    if (!command)
    {
        //如果没有入参,则回调JS失败函数
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"没有alert title"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:@"没有入参"];
        return;
    }
    
    [[ESDeviceCommand sharedESDeviceCommand] getDeviceList:^(NSArray *deviceAry){
        NSString* titleString = command.arguments[0];
        if (!deviceAry.count)
        {
            //mock
            ESDevice *device = [ESDevice new];
            device.devicename = @"mock1111";
            deviceAry = @[device];
        }
        NSString *title = [NSString stringWithFormat:@"%@", titleString];
        UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        for (ESDevice *device in deviceAry)
        {
            UIAlertAction *action = [UIAlertAction actionWithTitle:device.devicename style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"连接棒子");
                
                [ESDeviceCommand connectDevice:device];
                self.connectedDevice = device;
                
                //成功回调函数
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:device.devicename];
                //通过cordova框架中的callBackID回调至JS的回调函数上
                NSLog(@"%@",command.callbackId);
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                
            }];
            [alertViewController addAction:action];
        }
        
        UIAlertAction *refreshAction = [UIAlertAction actionWithTitle:@"刷新列表" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"刷新棒子列表");
            
            [self showEshareDevices:command];
        }];
        
        [alertViewController addAction:refreshAction];
        
        UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        [alertViewController addAction:cancleAction];
        
        [self.viewController presentViewController:alertViewController animated:YES completion:nil];
        
    }];
    
    
    
}
//断开棒子连接
- (void)disconnectDevice:(dispatch_block_t)successBlock
{
    //    [[ESDeviceCommand sharedESDeviceCommand] stopChectACK];
    //    [ESDeviceCommand disconnectDevice:YES cb:^(BOOL finish) {
    //        NSLog(@"断开设备连接");
    self.transHttp = @"";
    self.connectedDevice = nil;
    if (successBlock)
    {
        successBlock();
    }
    //    }];
}
//开始连接
-(void)startMirror:(CDVInvokedUrlCommand *)command
{
    if (self.connectedDevice)
    {
        [ESDeviceCommand startMirror:^(UIImage *data) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.screenImg.image = data;
            });
        }];
    }
    else
    {
        return;
    }
}

//启动文件传送
- (void)startFileTrans:(CDVInvokedUrlCommand *)command
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self _adInitSavePath];
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_cmCloudCastDidConnect:) name:TcpSocketdidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_cmAckTimeoutNotice:) name:ACKTimeOutNotification object:nil];
    [[self httpManager] startHttpServer];
    [[ESDeviceCommand sharedESDeviceCommand] setReciveBordCastTime:120.0f];
    
    NSString *httpAdd = [Global getHttpAddress];
    
    //成功回调函数
    //创建一个回调对象并附上String类型参数
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:httpAdd];
    NSLog(@"___%@",command.callbackId);
    //通过cordova框架中的callBackID回调至JS的回调函数上
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
    
    //    //失败回调函数
    //    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"没有入参alert title"];
    //    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

//通过eshare打开文件
- (void)openFileInEshare:(CDVInvokedUrlCommand *)command
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self _adInitSavePath];
    });
    
    if (!command)
    {
        //如果没有入参,则回调JS失败函数
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"没有入参"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    //mock 正式开启
    if (!self.connectedDevice)
    {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"未连接设备"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSString *fileName = command.arguments[0];
    fileName = [@"/" stringByAppendingString:fileName];
    NSString *folderPath = [Global getMountPath];
    NSString *fileNamePath = [folderPath stringByAppendingString:fileName];
    
    FileType fileType = [ESLocalFileCommand getFileType:fileNamePath];
    if (fileType != kFileTypeVideo && fileType != kFileTypeAudio)
    {
        [ESLocalFileCommand OpenFile:fileNamePath fileType:fileType];
        return;
    }
    
    fileName = [fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [ESLocalFileCommand OpenFile:fileName fileType:fileType];
    
}


- (void)audioPlayAction:(MPMediaItem *)item filename:(NSString *)filename
{
    [TSLibraryImport startImportAsset:item cb:^(int code) {
        if (code==SUCCED) {
            NSString * path = [[[Global getItuneMusicPath] stringByAppendingPathComponent:filename] substringFromIndex:[[Global getMountPath] length]];
            path = [path stringByRemovingPercentEncoding];
            NSLog(@"%@", path);
            [ESLocalFileCommand OpenFile:path fileType:kFileTypeAudio];
            
        } else {
            NSLog(@"推送失败");
        }
    }];
}

- (void)_cmCloudCastDidConnect:(NSNotification*)notify {
    NSLog(@"%@", notify);
    
    [ESDeviceCommand sayHello:TYPE_IPHONE];
    [[ESDeviceCommand sharedESDeviceCommand] startChectACK];
}

- (void)_cmAckTimeoutNotice:(NSNotification*)notify {
    NSLog(@"%@", notify);
    
    [self disconnectDevice:nil];
    self.connectedDevice = nil;
}

#pragma mark - setting
- (UIImageView *)screenImg
{
    if (!_screenImg)
    {
        _screenImg = [[UIImageView alloc] init];
        _screenImg.frame = self.viewController.view.frame;
        [self.viewController.view addSubview:self.screenImg];
    }
    return _screenImg;
}

- (ESHttpManage *)httpManager {
    if (!_httpManager) _httpManager = [[ESHttpManage alloc] init];
    return _httpManager;
}


-(void)_adInitSavePath
{
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [documentPaths objectAtIndex:0];
    NSString *workpath=[[NSString alloc] initWithFormat:@"%@/EShareFile",docDir];
    [Global initMountPath:workpath];
    NSString *ituneMusicPath = [[NSString alloc] initWithFormat:@"%@/.music",workpath];
    [Global initItunePath:ituneMusicPath];
    NSString *cameraPhotosPath = [[NSString alloc] initWithFormat:@"%@/.photo",workpath];
    [Global initCameraPhotosPath:cameraPhotosPath];
    NSString *cameraVideoPath = [[NSString alloc] initWithFormat:@"%@/.video",workpath];
    [Global initCameraVideoPath:cameraVideoPath];
    NSString *cachePhotoPath = [[NSString alloc] initWithFormat:@"%@/.cache",workpath];
    [Global initCachePhotosPath:cachePhotoPath];
    NSString *cameraCacheVideoPath  = [[NSString alloc] initWithFormat:@"%@/.cache_video",workpath];
    [Global initCameraCacheVideoPath:cameraCacheVideoPath ];
    NSString *webPath = [[NSString alloc] initWithFormat:@"%@/.eshareWeb",workpath];
    [Global copyWebFiles:webPath];
    NSString * name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    [[ESWebPage sharedESWebPage] setCompanyTitle:name];
    [[ESWebPage sharedESWebPage] setNetTitle:name];
}



@end
