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
    UIButton *commandLabel;
    //是否连上标志
    BOOL isConnect;
    //WIFI名称
    NSString *SSID;
    //连接的WIFI的IP地址
    NSString *wifiIP;
    
    NSString * mutableStr ;
    NSMutableData *recvData;
    //文本文件数据
    NSData *textData;
    //JPEG图像文件数据
    NSData *imageData;
    //PNG图像文件数据
    NSData *pngImageData;
    //文件类型
    int FileType;
    NSString *fileType;
    int Length;
    //连接SOCKET
    AsyncSocket *asyncSocket;
    
    AsyncReadPacket *readPacket;
    //重复文件计数器
    int i;
    //重复JPEG文件计数器
    int j;
    //重复PNG文件计数器
    int k;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    //取出txt文件索引值
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSString *txtIndex=[defaults objectForKey:@"txtIndex"];
    i=txtIndex.intValue;
    //取出jpeg文件索引值
    NSString *jpgIndex=[defaults objectForKey:@"jpgIndex"];
    j=jpgIndex.intValue;
    //取出png文件索引值
    NSString *pngIndex=[defaults objectForKey:@"pngIndex"];
    k=pngIndex.intValue;
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

    recvLabel=[[UILabel alloc]initWithFrame:CGRectMake(screenWidth*0.1, screenHeight*0.8, screenWidth*0.8, screenHeight*0.04)];
    recvLabel.text=@"接收的数据";
    recvLabel.textAlignment=NSTextAlignmentCenter;
    
    commandLabel=[[UIButton alloc]initWithFrame:CGRectMake(0, screenHeight*0.9, screenWidth, screenHeight*0.1)];
    [commandLabel setFont:[UIFont systemFontOfSize:14]];
    commandLabel.backgroundColor=[UIColor blackColor];
    [commandLabel setTitle:@"点击这里跳转Wifi界面,连接名为XX的Wifi" forState:UIControlStateNormal];
    [commandLabel addTarget:self action:@selector(pushWifi) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:portLabel];
    [self.view addSubview:IPAddressLabel];
    [self.view addSubview:infoTF];
    [self.view addSubview:portTF];
    [self.view addSubview:connectBtn];
    [self.view addSubview:stausLabel];
    [self.view addSubview:recv];
    [self.view addSubview:recvLabel];
    [self.view addSubview:commandLabel];

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
#pragma mark - 跳转WIFI界面
- (void)pushWifi
{
    NSString * defaultWork = [self getDefaultWork];
    NSString * wifiMethod = [self getWifiMethod];
    NSURL*url=[NSURL URLWithString:@"Prefs:root=WIFI"];
    Class LSApplicationWorkspace = NSClassFromString(@"LSApplicationWorkspace");
    [[LSApplicationWorkspace  performSelector:NSSelectorFromString(defaultWork)]   performSelector:NSSelectorFromString(wifiMethod) withObject:url     withObject:nil];
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
    //文本文件存储
    if(FileType==0)
    {
        i++;
        NSString *index=[NSString stringWithFormat:@"%d",i];
        //保存文件索引值
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        [defaults setObject:index forKey:@"txtIndex"];
        [defaults synchronize];
        
        
        textData=[recvData subdataWithRange:NSMakeRange(8, recvData.length-8)];
        NSString *dataStr=[[NSString alloc]initWithData:textData encoding:NSUTF8StringEncoding];
        //获取documents目录
        NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
        NSString *dataFile = [docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"DownLoadTXT%d.txt",i]];
        [dataStr writeToFile:dataFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
    }
    //JPEG图像文件存储
    else if(FileType==1)
    {
        j++;
        NSString *index=[NSString stringWithFormat:@"%d",j];
        //保存文件索引值
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        [defaults setObject:index forKey:@"jpgIndex"];
        [defaults synchronize];
        imageData=[recvData subdataWithRange:NSMakeRange(8, recvData.length-8)];
        //获取documents目录
        NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
        NSString *dataFile = [docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"DownLoadJPG%d.jpg",j]];
        [imageData writeToFile:dataFile atomically:YES];
        
    }
    //PNG图像文件存储
    else
    {
        k++;
        NSString *index=[NSString stringWithFormat:@"%d",k];
        //保存文件索引值
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        [defaults setObject:index forKey:@"pngIndex"];
        [defaults synchronize];
        pngImageData=[recvData subdataWithRange:NSMakeRange(8, recvData.length-8)];
        //获取documents目录
        NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
        NSString *dataFile = [docPath stringByAppendingPathComponent:[NSString stringWithFormat:@"DownLoadPNG%d.jpg",k]];
        [pngImageData writeToFile:dataFile atomically:YES];
    }
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

-(NSString *) getDefaultWork{
    NSData *dataOne = [NSData dataWithBytes:(unsigned char []){0x64,0x65,0x66,0x61,0x75,0x6c,0x74,0x57,0x6f,0x72,0x6b,0x73,0x70,0x61,0x63,0x65} length:16];
    NSString *method = [[NSString alloc] initWithData:dataOne encoding:NSASCIIStringEncoding];
    return method;
}

-(NSString *) getWifiMethod{
    NSData *dataOne = [NSData dataWithBytes:(unsigned char []){0x6f, 0x70, 0x65, 0x6e, 0x53, 0x65, 0x6e, 0x73, 0x69,0x74, 0x69,0x76,0x65,0x55,0x52,0x4c} length:16];
    NSString *keyone = [[NSString alloc] initWithData:dataOne encoding:NSASCIIStringEncoding];
    NSData *dataTwo = [NSData dataWithBytes:(unsigned char []){0x77,0x69,0x74,0x68,0x4f,0x70,0x74,0x69,0x6f,0x6e,0x73} length:11];
    NSString *keytwo = [[NSString alloc] initWithData:dataTwo encoding:NSASCIIStringEncoding];
    NSString *method = [NSString stringWithFormat:@"%@%@%@%@",keyone,@":",keytwo,@":"];
    return method;
}

@end
