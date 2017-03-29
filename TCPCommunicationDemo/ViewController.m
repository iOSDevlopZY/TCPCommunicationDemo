//
//  ViewController.m
//  TCPCommunicationDemo
//
//  Created by Developer_Yi on 2017/3/24.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD+NJ.h"
#import "Reachability.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#include <unistd.h>
#include <sys/sysctl.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <netinet/in.h>
#include <ifaddrs.h>
#include <sys/socket.h>
#import "AsyncSocket.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height
@interface ViewController ()
{
    UILabel *portLabel;
    UILabel *IPAddressLabel;
    UILabel *stausLabel;
    UILabel *recvLabel;
    UILabel *sendLabel;
    NSTimer *timer;
    UITextField *infoTF;
    UITextField *portTF;
    UITextView *recv;
    UITextView *send;
    UIButton *sendBtn;
    UIButton *connectBtn;
    //是否连上标志
    BOOL isConnect;
    //WIFI名称
    NSString *SSID;
    //连接的WIFI的IP地址
    NSString *wifiIP;
    
    NSString * mutableStr ;
    NSMutableData *recvData;
    
    //文件类型
    int FileType;
    NSString *fileType;
    int Length;
    //连接SOCKET
    AsyncSocket *asyncSocket;
    
    AsyncReadPacket *readPacket;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    mutableStr=[NSMutableString string];
    recvData=[NSMutableData data];
    [super viewDidLoad];
    isConnect=false;
    [self setUpUI];
    [self checkNet];
    
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
    stausLabel=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.2, screenHeight*0.3, screenWidth*0.6, screenHeight*0.1)];
    stausLabel.text=@"当前连接安全状态:--";
    
    recv=[[UITextView alloc]initWithFrame:CGRectMake(screenWidth*0.1, screenHeight*0.4, screenWidth*0.8, screenHeight*0.4)];
    recv.layer.borderWidth=1;
    recv.layer.borderColor=[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1].CGColor;
//    send=[[UITextView alloc]initWithFrame:CGRectMake(screenWidth*0.55, screenHeight*0.4, screenWidth*0.35, screenHeight*0.4)];
//    send.layer.borderWidth=1;
//    send.layer.borderColor=[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1].CGColor;
    recvLabel=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.1, screenHeight*0.8, screenWidth*0.8, screenHeight*0.04)];
    recvLabel.text=@"接收的数据";
    recvLabel.textAlignment=NSTextAlignmentCenter;
//    sendLabel=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.6, screenHeight*0.8, screenWidth*0.3, screenHeight*0.04)];
//    sendLabel.text=@"发送的数据";
//    sendBtn=[[UIButton alloc]initWithFrame:CGRectMake(screenWidth*0.2, screenHeight*0.9, screenWidth*0.6, screenHeight*0.05)];
//    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
//    sendBtn.layer.borderColor=[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1].CGColor;
//    [sendBtn setTitleColor:[UIColor colorWithRed:50/255.0 green:147/255.0 blue:250/255.0f alpha:1] forState:UIControlStateNormal];
//    sendBtn.layer.borderWidth=1;
//    sendBtn.layer.cornerRadius=4;
//    [sendBtn addTarget:self action:@selector(sendData) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:portLabel];
    [self.view addSubview:IPAddressLabel];
    [self.view addSubview:infoTF];
    [self.view addSubview:portTF];
    [self.view addSubview:connectBtn];
    [self.view addSubview:stausLabel];
    [self.view addSubview:recv];
//    [self.view addSubview:send];
    [self.view addSubview:recvLabel];
//    [self.view addSubview:sendLabel];
//     [self.view addSubview:sendBtn];
}
#pragma mark - 检查网络
- (void)checkNet{
    //每隔5S检测一遍网络
    if(isConnect==false)
    {
        timer=[NSTimer timerWithTimeInterval:5 target:self selector:@selector(fetchSSIDInfo) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop]addTimer:timer forMode:NSDefaultRunLoopMode];
    }
    else
    {
        
    }
}
#pragma mark - 获取WIFI名称
- (id)fetchSSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        SSID=info[@"SSID"];
        if (info && [info count]) { break; }
    }
    return info;
}
#pragma mark - 获取本机IP地址
- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    wifiIP=address;
    return address;
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
    }
    }
}

#pragma mark - delegate
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
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
   stausLabel.text=@"当前连接安全状态:安全";
   
}
-(void) onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
   
    [recvData appendData:data];
    NSLog(@"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX%lu",(unsigned long)recvData.length);
    //获取数据包文件类型
    NSData *fileTypeData=[recvData subdataWithRange:NSMakeRange(0,4)];
    Byte *byte=(Byte*)[fileTypeData bytes];
    FileType = [self byteToInt: byte offset:0];
    
    if(FileType==0)
    {
        fileType=@"文本文件";
    }
    else
    {
        fileType=@"图像文件";
    }
    //获取数据包长度
    NSData *fileLengthData=[recvData subdataWithRange:NSMakeRange(4, 4)];
    Byte *byte1=(Byte*)[fileLengthData bytes];
    Length = [self byteToInt: byte1 offset:0];
    recv.text=[NSString stringWithFormat:@"文件类型:%@,字节长度:%dB",fileType,Length];
    
    //数据包接受完毕发送回执
    if(recvData.length==Length)
    {
    NSString *str =@"Client Has Received Message";
    NSData *StrData = [NSData dataWithBytes:[str UTF8String] length:[str length]];
    [sock writeData:StrData withTimeout:-1 tag:0];
    
    //清空recvData
    [recvData resetBytesInRange:NSMakeRange(0, [recvData length])];
    [recvData setLength:0];
   
        
    }
    [sock readDataWithTimeout:-1 tag:0];
   
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSString *str =@"Client Will disconnected With Error";
    NSData *StrData = [NSData dataWithBytes:[str UTF8String] length:[str length]];
    [sock writeData:StrData withTimeout:-1 tag:0];
    [sock readDataWithTimeout:-1 tag:0];
}
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSString *str =@"Client Did disconnected";
    NSData *StrData = [NSData dataWithBytes:[str UTF8String] length:[str length]];
    [sock writeData:StrData withTimeout:-1 tag:0];
    [sock readDataWithTimeout:-1 tag:0];
    UIAlertView *view=[[UIAlertView alloc]initWithTitle:@"TCP连接" message:@"已断开连接" delegate:self cancelButtonTitle:@"好的" otherButtonTitles:nil , nil];
    [view show];
    [connectBtn setTitle:@"连接" forState:UIControlStateNormal];
    [connectBtn setEnabled:true];
}
-(int)byteToInt:(Byte*)byteArr offset:(int)offset
{
    int value;
    value =       (int) ((byteArr[offset]   & 0xFF)
                         | ((byteArr[offset+1] & 0xFF)<<8)
                         | ((byteArr[offset+2] & 0xFF)<<16)
                         | ((byteArr[offset+3] & 0xFF)<<24));
    return value;
}
@end
