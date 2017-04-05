//
//  CheckNetClass.h
//  TCPCommunicationDemo
//
//  Created by Developer_Yi on 2017/4/5.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CheckNetClass : NSObject

//检查无线网络
+ (void)checkNet:(BOOL)isConnected;
+ (NSString *)getIPAddress;
+ (void)pushWifi;
//WIFI名称
@property(nonatomic,copy)NSString *SSID;
@end
