//
//  ViewController.m
//  TCPCommunicationDemo
//
//  Created by Developer_Yi on 2017/3/24.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD+NJ.h"
#import "AsyncSocket.h"
#import "CheckNetClass.h"
#import "FileOperationClass.h"
#import "QRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GetRouteIP.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UIDocumentInteractionControllerDelegate,AVCaptureMetadataOutputObjectsDelegate,QRCodeViewControllerDelegate>
{
    UILabel *portLabel;
    UILabel *IPAddressLabel;
    NSTimer *timer;
    UITextField *infoTF;
    UITextField *portTF;
    UIButton *connectBtn;
    UIButton *commandLabel;
    UIButton *disConnectBtn;
    UIButton *QRCodeBtn;
    UIButton *saveBtn;
    UILabel *recommandLabel;
    UILabel *patientName;
    UILabel *patientNameInfo;
    UILabel *patientAge;
    UILabel *patientAgeInfo;
    UILabel *patientSex;
    UILabel *patientSexInfo;
    UITableView *tableView1;
    //是否连上标志
    BOOL isConnect;
    NSMutableData *recvData;
    NSArray *fileArr;
    //文件类型
    int FileType;
    //文件名
    NSString *fileName;
    NSString *fileType;
    int Length;
    //连接SOCKET
    AsyncSocket *asyncSocket;
    //文件长度
    int fileNameLengthNum;
    NSString *fileNameStr;
    FileOperationClass *operationClass;
    AVCaptureSession *session;
    AVCaptureVideoPreviewLayer *layer;
}
//文件预览器
@property(nonatomic,strong)UIDocumentInteractionController *controller;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self initMutable];
    [self setUpUI];
    isConnect=false;
    [CheckNetClass checkNet:isConnect];
    operationClass=[[FileOperationClass alloc]init];
    //获取沙盒下所有文件
    fileArr=[operationClass getAllFileNames:@""];
}
#pragma mark - 初始化摄像头类
-(void)initAVSession
{
    bool isAuthorized=[self privacy];
    if(isAuthorized==true)
    {
        QRCodeViewController *qrVc = [[QRCodeViewController alloc] init];
        qrVc.delegate = self;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:qrVc];
        // 设置扫描完成后的回调
        __weak typeof (self) wSelf = self;
        [qrVc setCompletionWithBlock:^(NSString *resultAsString) {
            [wSelf.navigationController popViewControllerAnimated:YES];
        }];
        
        [self presentViewController:nav animated:YES completion:nil];
    }
    else
    {
        UIAlertView *alert =[[UIAlertView alloc]initWithTitle:@"权限提醒" message:@"请在iPhone的“设置”-“隐私”-“相机”功能中，找到“XXXX”打开相机访问权限" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
    }
    
}
#pragma mark - 判断相机权限
-(bool)privacy
{
    NSString *mediaType = AVMediaTypeVideo;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        return false;
    }
    return true;
}
#pragma mark - 初始化Mutable
- (void)initMutable
{
    recvData=[NSMutableData data];
}
#pragma mark - 设置UI
- (void)setUpUI {
    //网络状态Label
    IPAddressLabel=[[UILabel alloc]init];
    IPAddressLabel.frame=CGRectMake(screenWidth*0.1, 44, screenWidth*0.3, screenHeight*0.1);
    IPAddressLabel.textAlignment=NSTextAlignmentLeft;
    IPAddressLabel.text=@"连接IP地址";
    
    //WIFI地址Label
    portLabel=[[UILabel alloc]init];
    portLabel.frame=CGRectMake(screenWidth*0.1,88, screenWidth, screenHeight*0.1);
    portLabel.textAlignment=NSTextAlignmentLeft;
    portLabel.text=@"连接端口号";
    
    infoTF=[[UITextField alloc]initWithFrame:CGRectMake(screenWidth*0.4, 64, screenWidth*0.4, screenHeight*0.05)];
    infoTF.borderStyle=UITextBorderStyleRoundedRect;
    infoTF.text=@"192.168.159.1";
    
    portTF=[[UITextField alloc]initWithFrame:CGRectMake(screenWidth*0.4, 108, screenWidth*0.4, screenHeight*0.05)];
    portTF.borderStyle=UITextBorderStyleRoundedRect;
    portTF.text=@"5050";
    
    QRCodeBtn=[[UIButton alloc]initWithFrame:CGRectMake(screenWidth*0.85, 64, screenWidth*0.1, screenHeight*0.05)];
    [QRCodeBtn setImage:[UIImage imageNamed:@"QRCode"] forState:UIControlStateNormal];
    [QRCodeBtn addTarget:self action:@selector(scan) forControlEvents:UIControlEventTouchUpInside];
    
    connectBtn=[[UIButton alloc]initWithFrame:CGRectMake(screenWidth*0.2, screenHeight*0.25, screenWidth*0.6, screenHeight*0.05)];
    [connectBtn setTitle:@"连接" forState:UIControlStateNormal];
    [connectBtn setTitleColor:[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1] forState:UIControlStateNormal];
    connectBtn.layer.borderWidth=1;
    connectBtn.layer.cornerRadius=4;
    connectBtn.layer.borderColor=[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1].CGColor;
    [connectBtn addTarget:self action:@selector(connectSocket) forControlEvents:UIControlEventTouchUpInside];
    
    disConnectBtn=[[UIButton alloc]initWithFrame:CGRectMake(screenWidth*0.2, screenHeight*0.32, screenWidth*0.6, screenHeight*0.05)];
    [disConnectBtn setTitle:@"断开连接" forState:UIControlStateNormal];
    [disConnectBtn setTitleColor:[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1] forState:UIControlStateNormal];
    disConnectBtn.layer.borderWidth=1;
    disConnectBtn.layer.cornerRadius=4;
    disConnectBtn.layer.borderColor=[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1].CGColor;
    [disConnectBtn addTarget:self action:@selector(disconnectSocket) forControlEvents:UIControlEventTouchUpInside];
    disConnectBtn.enabled=false;
    
    commandLabel=[[UIButton alloc]initWithFrame:CGRectMake(0, screenHeight*0.9, screenWidth, screenHeight*0.1)];
    [commandLabel setFont:[UIFont systemFontOfSize:14]];
    commandLabel.backgroundColor=[UIColor blackColor];
    [commandLabel setTitle:@"点击这里跳转Wifi界面,连接名为XX的Wifi" forState:UIControlStateNormal];
    [commandLabel addTarget:self action:@selector(pushWifi) forControlEvents:UIControlEventTouchUpInside];
    
    patientName=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.1, screenHeight*0.42, screenWidth*0.3, screenHeight*0.03)];
    patientName.text=@"患者姓名";
    patientName.textAlignment=NSTextAlignmentCenter;
    
    patientNameInfo=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.6, screenHeight*0.42, screenWidth*0.3, screenHeight*0.03)];
    patientNameInfo.text=@"";
    patientNameInfo.textAlignment=NSTextAlignmentCenter;
    
    patientAge=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.1, screenHeight*0.47, screenWidth*0.3, screenHeight*0.03)];
    patientAge.text=@"患者年龄";
    patientAge.textAlignment=NSTextAlignmentCenter;
    
    patientAgeInfo=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.6, screenHeight*0.47, screenWidth*0.3, screenHeight*0.03)];
    patientAgeInfo.text=@"";
    patientAgeInfo.textAlignment=NSTextAlignmentCenter;
    
    patientSex=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.1, screenHeight*0.52, screenWidth*0.3, screenHeight*0.03)];
    patientSex.text=@"患者性别";
    patientSex.textAlignment=NSTextAlignmentCenter;
    
    patientSexInfo=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.6, screenHeight*0.52, screenWidth*0.3, screenHeight*0.03)];
    patientSexInfo.text=@"";
    patientSexInfo.textAlignment=NSTextAlignmentCenter;
    
    saveBtn=[[UIButton alloc]initWithFrame:CGRectMake(screenWidth*0.2, screenHeight*0.55, screenWidth*0.6, screenHeight*0.05)];
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1] forState:UIControlStateNormal];
    saveBtn.layer.borderWidth=1;
    saveBtn.layer.cornerRadius=4;
    saveBtn.layer.borderColor=[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1].CGColor;
    [saveBtn addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    
    tableView1=[[UITableView alloc]initWithFrame:CGRectMake(0, screenHeight*0.62, screenWidth, screenHeight*0.28)];
    tableView1.delegate=self;
    tableView1.dataSource=self;

    [self.view addSubview:portLabel];
    [self.view addSubview:IPAddressLabel];
    [self.view addSubview:infoTF];
    [self.view addSubview:portTF];
    [self.view addSubview:connectBtn];
    [self.view addSubview:disConnectBtn];
    [self.view addSubview:QRCodeBtn];
    [self.view addSubview:commandLabel];
    [self.view addSubview:patientName];
    [self.view addSubview:patientNameInfo];
    [self.view addSubview:patientAge];
    [self.view addSubview:patientAgeInfo];
    [self.view addSubview:patientSex];
    [self.view addSubview:patientSexInfo];
    [self.view addSubview:saveBtn];
    [self.view addSubview:tableView1];

}
#pragma mark - 发送JSON数据
- (void)save
{
    NSDictionary *json = @{
                           @"Type" :@"GetCurrentPatientExamination"
                        };
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [self sendCallBack:data];
}
#pragma mark - 扫描二维码
- (void)scan
{
    //初始化摄像头类
    [self initAVSession];
}
#pragma mark - 连接wifi
- (void)pushWifi
{
    
    [CheckNetClass pushWifi];
}
#pragma mark - 连接socket
- (void)connectSocket
{
    if((IPAddressLabel.text==nil||[IPAddressLabel.text isEqualToString:@""])||(portTF.text==nil||[portTF.text isEqualToString:@""]))
    {
        UIAlertView *view=[[UIAlertView alloc]initWithTitle:@"错误" message:@"IP地址和端口号不能为空" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil , nil];
        [view show];
    }
    else{
    asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
    [asyncSocket enablePreBuffering];
    NSError *err = nil;
    if(![asyncSocket connectToHost:infoTF.text onPort:portTF.text.intValue error:&err])
        {
                UIAlertView *view=[[UIAlertView alloc]initWithTitle:@"TCP错误" message:@"未能连接制定的IP地址和端口号" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil , nil];
                [view show];
        }
    else
        {
                [connectBtn setTitle:@"连接中" forState:UIControlStateNormal];
                [connectBtn setEnabled:false];
                [disConnectBtn setEnabled:true];
        }
    }
    
}
#pragma mark - 断开连接socket
- (void)disconnectSocket
{
    [connectBtn setTitle:@"连接" forState:UIControlStateNormal];
    [connectBtn setEnabled:true];
    [disConnectBtn setEnabled:false];
    NSDictionary *json = @{
                           @"Type" :@"ClientExit"
                           };
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
    [self sendCallBack:data];
    [asyncSocket readDataWithTimeout:-1 tag:0];
    UIAlertView *view=[[UIAlertView alloc]initWithTitle:@"TCP连接" message:@"已断开连接" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil , nil];
    [view show];

}
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)reader:(QRCodeViewController *)reader didScanResult:(NSString *)result
{
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:result options:0];    
        NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        infoTF.font=[UIFont systemFontOfSize:15];
    }];
}
#pragma mark - delegate
- (void)onSocket:(AsyncSocket*)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    UIAlertView *view=[[UIAlertView alloc]initWithTitle:@"TCP连接" message:@"已成功连接" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil , nil];
    [view show];
    [connectBtn setTitle:@"已连接" forState:UIControlStateNormal];
    [connectBtn setEnabled:false];
    //连接成功时必须要写这个方法，否则无法接收服务器数据
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didSecure:(BOOL)flag
{
  
   
}
-(void) onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [recvData appendData:data];
    //长度指令没有收全
    if(recvData.length<4)
    {
        [sock readDataWithTimeout:-1 tag:0];
        [recvData appendData:data];
    }
    //长度指令收全
    else
    {
        //获取文件长度
        Length=[operationClass readDataLength:recvData];
        //类型指令没有收全
        if(recvData.length<8)
        {
            [sock readDataWithTimeout:-1 tag:0];
            [recvData appendData:data];
        }
        else
        {
            FileType=[operationClass readDataType:recvData];
            //数据包没有收全
            if(recvData.length<Length+4)
            {
                [sock readDataWithTimeout:-1 tag:0];
                [recvData appendData:data];
            }
            //正好收全
            else if(recvData.length==Length+4)
            {
                NSData *data=[recvData subdataWithRange:NSMakeRange(8, recvData.length-8)];
                [self paralize:data];
                [recvData resetBytesInRange:NSMakeRange(0, [recvData length])];
                [recvData setLength:0];
                [sock readDataWithTimeout:-1 tag:0];
            }
            //超出
            else
            {
                NSData* subData=[recvData subdataWithRange:NSMakeRange(8, Length+4)];
                [self paralize:subData];
                recvData=[[recvData subdataWithRange:NSMakeRange(Length+4, recvData.length-Length-4)] mutableCopy];
                [sock readDataWithTimeout:-1 tag:0];
                [recvData appendData:data];
            }
        }
    }
    
}

#pragma mark-解析文件
- (void)paralize:(NSData*)data
{
    //指令文件
    if(FileType==0)
    {
       
        NSDictionary *dic=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSLog(@">>>>>>>>>>>>>>>>%@",dic);
        if([dic[@"Type"]isEqualToString:@"Patientinfo"])
        {
            patientNameInfo.text=dic[@"Name"];
            patientAgeInfo.text=dic[@"Age"];
            patientSexInfo.text=dic[@"Gender"];
        }
        else if([dic[@"Type"]isEqualToString:@"GetCurrentPatientExaminationReply"])
        {
            NSString *guid=dic[@"Guid"];
            NSDictionary *json = @{
                                   @"Type" :@"StartSendPatientExamination",
                                   @"Guid":guid
                                   };
            NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
            [self sendCallBack:data];
        }
        else if([dic[@"Type"]isEqualToString:@"StartSendFile"])
        {
            fileNameStr=dic[@"FileName"];
        }
    }
    //数据文件
    else
    {
        NSData *data=[recvData subdataWithRange:NSMakeRange(8, recvData.length-8)];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths objectAtIndex:0];
        NSString *filePath = [path stringByAppendingPathComponent:fileNameStr];
        [data writeToFile:filePath atomically:YES];
        fileArr=[operationClass getAllFileNames:@""];
        [tableView1 reloadData];
    }
}


- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    [sock readDataWithTimeout:-1 tag:0];
}
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    [sock readDataWithTimeout:-1 tag:0];
    [connectBtn setTitle:@"连接" forState:UIControlStateNormal];
    [connectBtn setEnabled:true];
    [disConnectBtn setEnabled:false];
}
#pragma mark- TableViewDelegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   if(fileArr.count>0)
   {
       return fileArr.count;
   }
    else
    {
        return 0;
    }
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    if(fileArr.count>0)
    {
        cell.textLabel.text=fileArr[indexPath.row];
    }
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger i=indexPath.row;
    NSURL *url=[operationClass previewFileURL:fileArr :i];
    //预览文档
    self.controller = [UIDocumentInteractionController  interactionControllerWithURL:url];
    self.controller.delegate=self;
    [self.controller presentPreviewAnimated:YES];
}

#pragma mark -UIDocumentControllerDelegate

- (UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController*)controller
{
    return self;
}
- (UIView*)documentInteractionControllerViewForPreview:(UIDocumentInteractionController*)controller
{
    return self.view;
}
- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController*)controller
{
    
   return self.view.frame;
}
- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController*)_controller
{
    [self.controller dismissPreviewAnimated:YES];
}
#pragma mark -发送回执
- (void)sendCallBack:(NSData*)data
{
    [asyncSocket writeData:data withTimeout:-1 tag:0];
}
@end
