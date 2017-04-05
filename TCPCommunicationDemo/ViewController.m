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

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,UIDocumentInteractionControllerDelegate>
{
    UILabel *portLabel;
    UILabel *IPAddressLabel;
    NSTimer *timer;
    UITextField *infoTF;
    UITextField *portTF;
    UIButton *connectBtn;
    UIButton *commandLabel;
    UIButton *disConnectBtn;
    UILabel *recommandLabel;
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
    FileOperationClass *operationClass;
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
    
    infoTF=[[UITextField alloc]initWithFrame:CGRectMake(screenWidth*0.5, 64, screenWidth*0.4, screenHeight*0.05)];
    infoTF.borderStyle=UITextBorderStyleRoundedRect;
    infoTF.text=@"192.168.191.1";
    
    portTF=[[UITextField alloc]initWithFrame:CGRectMake(screenWidth*0.5, 108, screenWidth*0.4, screenHeight*0.05)];
    portTF.borderStyle=UITextBorderStyleRoundedRect;
    portTF.text=@"5050";
    
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

    recommandLabel=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.1, screenHeight*0.38, screenWidth*0.8, screenHeight*0.03)];
    recommandLabel.text=@"应用沙盒目录下的文件";
    recommandLabel.textAlignment=NSTextAlignmentCenter;
    
    commandLabel=[[UIButton alloc]initWithFrame:CGRectMake(0, screenHeight*0.9, screenWidth, screenHeight*0.1)];
    [commandLabel setFont:[UIFont systemFontOfSize:14]];
    commandLabel.backgroundColor=[UIColor blackColor];
    [commandLabel setTitle:@"点击这里跳转Wifi界面,连接名为XX的Wifi" forState:UIControlStateNormal];
    [commandLabel addTarget:self action:@selector(pushWifi) forControlEvents:UIControlEventTouchUpInside];

    tableView1=[[UITableView alloc]initWithFrame:CGRectMake(0, screenHeight*0.42, screenWidth, screenHeight*0.48)];
    tableView1.delegate=self;
    tableView1.dataSource=self;

    [self.view addSubview:portLabel];
    [self.view addSubview:IPAddressLabel];
    [self.view addSubview:infoTF];
    [self.view addSubview:portTF];
    [self.view addSubview:connectBtn];
     [self.view addSubview:disConnectBtn];
    [self.view addSubview:commandLabel];
    [self.view addSubview:recommandLabel];
    [self.view addSubview:tableView1];

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
    NSString *str =@"Client Did disconnected";
    [self sendCallBack:str];
    [asyncSocket readDataWithTimeout:-1 tag:0];
    UIAlertView *view=[[UIAlertView alloc]initWithTitle:@"TCP连接" message:@"已断开连接" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil , nil];
    [view show];

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
    //获取文件类型
    FileType=[operationClass readDataType:recvData];
    //获取文件长度
    Length=[operationClass readDataLength:recvData];
    //获取文件名长度
    fileNameLengthNum=[operationClass readDataNameLength:recvData];
    //数据包接受完毕发送回执
    if(recvData.length==Length)
    {
        //读取文件名
        fileName=[operationClass readDataFileName:recvData];
    //文本文件存储
    if(FileType==0)
    {
        [operationClass writeTxtFile:recvData];
        //获取沙盒下所有文件
        fileArr=[operationClass getAllFileNames:@""];
        [tableView1 reloadData];
    }
    //JPEG图像文件存储
    else if(FileType==1)
    {
        [operationClass writeJPGFile:recvData];
        //获取沙盒下所有文件
        fileArr=[operationClass getAllFileNames:@""];
        [tableView1 reloadData];
        
    }
    //PNG图像文件存储
    else if(FileType==2)
    {
        [operationClass writePNGFile:recvData];
        //获取沙盒下所有文件
        fileArr=[operationClass getAllFileNames:@""];
        [tableView1 reloadData];
    }
    //.dcm图像文件存储
    else
    {
        [operationClass writeDMIFile:recvData];
        //获取沙盒下所有文件
        fileArr=[operationClass getAllFileNames:@""];
        [tableView1 reloadData];
    }
    //清空recvData
    [recvData resetBytesInRange:NSMakeRange(0, [recvData length])];
    [recvData setLength:0];
    //发送回执
    NSString *str =@"Client Has Received Message";
    [self sendCallBack:str];
    }
    [sock readDataWithTimeout:-1 tag:0];
    
   
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSString *str =@"Client Will disconnected With Error";
    [self sendCallBack:str];
    [sock readDataWithTimeout:-1 tag:0];
}
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSString *str =@"Client Did disconnected";
    [self sendCallBack:str];;
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
- (void)sendCallBack:(NSString*)callBack
{
    NSData *StrData = [NSData dataWithBytes:[callBack UTF8String] length:[callBack length]];
    [asyncSocket writeData:StrData withTimeout:-1 tag:0];
}
@end
