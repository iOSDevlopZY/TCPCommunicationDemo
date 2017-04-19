//
//  FileOperationClass.m
//  TCPCommunicationDemo
//
//  Created by Developer_Yi on 2017/4/5.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "FileOperationClass.h"

@implementation FileOperationClass

#pragma mark - 获取沙盒下是所有文件
-(NSArray *) getAllFileNames:(NSString *)dirName
{
    // 获得此程序的沙盒路径
    NSArray *patchs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    // 获取Documents路径
    // [patchs objectAtIndex:0]
    NSString *documentsDirectory = [patchs objectAtIndex:0];
    
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory error:nil];
    return files;
}

#pragma mark - 获取头部信息
-(int)readDataType:(NSMutableData*)recvData
{
    //获取数据包文件类型
    NSData *fileTypeData=[recvData subdataWithRange:NSMakeRange(4,4)];
    Byte *byte=(Byte*)[fileTypeData bytes];
    int FileType = [self byteToInt: byte offset:0];
    return FileType;
}

#pragma mark - 获取文件长度
-(int)readDataLength:(NSMutableData*)recvData
{
    //获取数据包长度
    NSData *fileLengthData=[recvData subdataWithRange:NSMakeRange(0, 4)];
    Byte *byte1=(Byte*)[fileLengthData bytes];
    int Length = [self byteToInt: byte1 offset:0];
    return Length;
}

#pragma mark - 获取json数据
-(NSData*)getJson:(NSMutableData*)recvData
{
    NSData* textData=[recvData subdataWithRange:NSMakeRange(8, recvData.length-8)];
    return textData;
}
#pragma maek - 预览文件
-(NSURL*)previewFileURL:(NSArray*)fileArr:(NSInteger)index
{
    NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dataFile = [docPath stringByAppendingPathComponent:fileArr[index]];
    NSURL *url=[NSURL fileURLWithPath:dataFile];
    return url;
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
