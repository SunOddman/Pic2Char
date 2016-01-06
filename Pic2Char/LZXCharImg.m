//
//  LZXCharImg.m
//  Pic2Char
//
//  Created by 海底捞lzx on 15/12/12.
//  Copyright © 2015年 海底捞. All rights reserved.
//

#import "LZXCharImg.h"
#import "LZXRecognizor.h"
#import "NSImage+ColorAtPixel.h"

@interface LZXCharImg ()

@property (nonatomic, strong) NSMutableArray *outputStrs;

@end

char charSet[] = {' ', '.', ',', ':', '|', 'I', 'P', 'N', 'B', 'M'};

@implementation LZXCharImg

+ (instancetype)sharedCharImg {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return  sharedInstance;
}

- (NSImage *)charsImageWithImage:(NSImage *)imgOriginal {
    
    NSArray<NSImage *> *arrFrames = imgOriginal.gifFrames;
    NSMutableArray<NSImage *> *imgsArr = [[NSMutableArray<NSImage *> alloc] initWithCapacity:arrFrames.count];
    
    
    for (NSImage *imgF in arrFrames) {
        NSImage *imgReturn;
        
        // 1. NSImage 转 CGImage
        CGImageRef img = imgF.CGImage;
        
        // 2. 获取图像信息
        UInt32 *pixels = imgF.Colors;
        NSInteger w = CGImageGetWidth(img);
        NSInteger h = CGImageGetHeight(img);
        CGImageRelease(img);
        
        // 3. 划分图像区域，获取对应区域的平均颜色信息
        int cellW = 1;
        long countH = w / cellW;
        int cellH = 2;
        long countV = h / cellH;
        
        UInt32 *pis = (UInt32 *) calloc(countH * countV, sizeof(UInt32));
        UInt32 *pis0 = pis;
        UInt32 *tmpC = (UInt32 *) calloc(cellW * cellW, sizeof(UInt32));
        for (int j = 0; j < countV; j ++) {
            for (int i = 0; i < countH; i ++) {
                UInt32 *tmp = tmpC;
                UInt32 r = 0;
                UInt32 g = 0;
                UInt32 b = 0;
                UInt32 a = 0;
                for (int k = 0; k < cellW * cellH; k ++) {
                    int offset = (int)((i * cellW + k % cellW) + (j * cellH + k / cellW) * w);
                    *tmp = *(pixels + offset);
                    r += R(*tmp);
                    g += G(*tmp);
                    b += B(*tmp);
                    a += A(*tmp);
                    tmp ++;
                }
                r /= (cellW * cellH);
                g /= (cellW * cellH);
                b /= (cellW * cellH);
                a /= (cellW * cellH);
                *pis = RGBAMake(MAX(0,MIN(255, r)), MAX(0,MIN(255, g)), MAX(0,MIN(255, b)), MAX(0,MIN(255, a)));
                pis ++;
            }
        }
        
        // 4. 压缩后的图像颜色数组
        self.outputStrs = [NSMutableArray arrayWithCapacity:countV];
        NSMutableString *output = [NSMutableString stringWithCapacity:countV * countH];
        UInt *pis1 = pis0;
        for (NSUInteger j = 0; j < countV; j++) {
            for (NSUInteger i = 0; i < countH; i++) {
                UInt32 color = *pis1;
                // 5. 获取图像灰度
                UInt32 brightness = (R(color)+G(color)+B(color))/3.0;
                
                // 6. 匹配字符
                UInt32 brIdx = brightness / 26;
                [output appendFormat:@"%c", charSet[9 - brIdx]];
                //            printf("%1c", charSet[9 - brIdx]);
                pis1 ++;
            }
            [output appendString:@"\n"];
            //        printf("\n");
        }
        NSString *output1 = [output substringToIndex:output.length - 2];
        free(pixels);
        free(pis0);
        free(tmpC);
        
        // 7. 图像转字符图片
        imgReturn = [[NSImage alloc] initWithSize:CGSizeMake(w * 11, h * 11)];
        [imgReturn lockFocus];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
        paragraphStyle.lineSpacing = 0.0f;
        paragraphStyle.lineHeightMultiple = 0.0f;
        paragraphStyle.headIndent = 0.0f;
        paragraphStyle.minimumLineHeight = 1.0f;
        paragraphStyle.maximumLineHeight = 21.0f;
        paragraphStyle.paragraphSpacingBefore = 0.0f;
        paragraphStyle.paragraphSpacing = 0.0f;
        paragraphStyle.firstLineHeadIndent = 0.0f;
        paragraphStyle.headIndent = 0.0f;
        paragraphStyle.paragraphSpacingBefore = 0.0f;
        NSDictionary *attrDict = @{
                                   NSForegroundColorAttributeName : [NSColor blackColor],
                                   NSParagraphStyleAttributeName : paragraphStyle,
                                   NSFontAttributeName : [NSFont fontWithName:@"Menlo Bold" size:17],
                                   NSKernAttributeName : @0.5f
                                   };
        NSRect rec = [output1 boundingRectWithSize:imgReturn.size
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:attrDict];
        [output1 drawInRect:rec withAttributes:attrDict];
        [imgReturn unlockFocus];
        
        [imgsArr addObject:imgReturn];
    }
    
    NSData *data = [imgsArr dataOfGifFramesWithDuration:imgOriginal.duration];
    NSImage *imgReturn = [[NSImage alloc] initWithData:data];
    return imgReturn;
}@end
