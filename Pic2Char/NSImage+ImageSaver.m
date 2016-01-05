//
//  NSImage+ImageSaver.m
//  Pic2Char
//
//  Created by 海底捞lzx on 15/12/25.
//  Copyright © 2015年 海底捞. All rights reserved.
//

#import "NSImage+ImageSaver.h"
#import "NSImage+ColorAtPixel.h"

@interface NSImage()



@end

@implementation NSImage (ImageSaver)


- (BOOL)saveImageToURL:(NSURL *)url {
    BOOL result = YES;
    NSString *path = [url path];
    NSBitmapImageFileType type = ^(){
        NSString *typeStr = [[path pathExtension] lowercaseString];
        if ([typeStr isEqualToString:@"png"]) {
            return NSPNGFileType;
        } else if ([typeStr isEqualToString:@"jpg"]) {
            return NSJPEGFileType;
        } else if ([typeStr isEqualToString:@"bmp"]) {
            return NSBMPFileType;
        } else if ([typeStr isEqualToString:@"gif"]) {
            return NSGIFFileType;
        } else {
            return NSTIFFFileType;
        }
    }();
    
    if (type == NSGIFFileType) {
        // 如果为 gif，可以直接将计算好的 data 写入 文件
        return [self.data writeToFile:path atomically:YES];
    }
    
    CGImageRef imgRef = self.CGImage;
    CGSize size = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGImageRelease(imgRef);
    
    [self lockFocus];
    //先设置 下面一个实例
    NSBitmapImageRep *bits = [[NSBitmapImageRep alloc]initWithFocusedViewRect:NSMakeRect(0, 0, size.width, size.height)];
    [self unlockFocus];
    
    //再设置后面要用到得props属性
    NSDictionary *imageProps = [NSDictionary dictionary];//[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor];
    
    //之后 转化为NSData 以便存到文件中
    NSData *imageData = [bits representationUsingType:type properties:imageProps];
    
    //设定好文件路径后进行存储就ok了
    result = [imageData writeToFile:path atomically:YES];
    return result;
}

@end
