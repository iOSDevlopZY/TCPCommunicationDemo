//
//  FileOperationClass.h
//  TCPCommunicationDemo
//
//  Created by Developer_Yi on 2017/4/5.
//  Copyright © 2017年 mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileOperationClass : NSObject

@property(nonatomic,assign)int fileNameLengthNumOne;
@property(nonatomic,assign)NSString* fileName;

-(NSArray *) getAllFileNames:(NSString *)dirName;
-(int)readDataType:(NSMutableData*)recvData;
-(int)readDataLength:(NSMutableData*)recvData;
-(NSData*)getJson:(NSMutableData*)recvData;



-(NSURL*)previewFileURL:(NSArray*)fileArr:(NSInteger)index;
@end
