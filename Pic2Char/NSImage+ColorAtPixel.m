//
//  NSImage+ColorAtPixel.m
//  Pic2Char
//
//  Created by 海底捞lzx on 15/12/18.
//  Copyright © 2015年 海底捞. All rights reserved.
//

#import "NSImage+ColorAtPixel.h"
#import <objc/runtime.h>

@interface NSImage () {
}


@end

@implementation NSImage (ColorAtPixel)

#pragma mark -

/*
 A category on UIImage that enables you to query the color value of arbitrary
 pixels of the image.
 */

- (NSUInteger)w {
    CGImageRef inputCGImage = self.CGImage;
    NSUInteger width = CGImageGetWidth(inputCGImage);
    return width;
}

- (NSUInteger)h {
    CGImageRef inputCGImage = self.CGImage;
    NSUInteger height = CGImageGetHeight(inputCGImage);
    return height;
}

- (UInt32 *)Colors {
    // 1.
    CGImageRef inputCGImage = self.CGImage;
    NSUInteger width = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    
    // 2.
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    UInt32 * pixels;
    pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
    
    // 3.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpace,     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // 4.
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
    // 5. Cleanup
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    // 1. 宏定义（在 .h 中）

    
//    // 2.
//    NSLog(@"Brightness of image:");
//    UInt32 * currentPixel = pixels;
//    for (NSUInteger j = 0; j < height; j++) {
//        for (NSUInteger i = 0; i < width; i++) {
//            // 3.
//            UInt32 color = *currentPixel;
//            printf("%3.0f ", (R(color)+G(color)+B(color))/3.0);
//            // 4.
//            currentPixel++;
//        }
//        printf("\n");
//    }
    
    
    return pixels;
}


- (NSColor *)colorAtPixel:(CGPoint)point {
    // Cancel if point is outside image coordinates
    if (!CGRectContainsPoint(CGRectMake(0.0f, 0.0f, self.size.width, self.size.height), point)) {
        return nil;
    }
    NSInteger pointX = trunc(point.x);
    NSInteger pointY = trunc(point.y);
    CGImageRef cgImage = self.CGImage;
    NSUInteger width = self.size.width;
    NSUInteger height = self.size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int bytesPerPixel = 4;
    int bytesPerRow = bytesPerPixel * 1;
    NSUInteger bitsPerComponent = 8;
    unsigned char pixelData[4] = { 0, 0, 0, 0 };
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 1,
                                                 1,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    
    // Draw the pixel we are interested in onto the bitmap context
    CGContextTranslateCTM(context, -pointX, pointY-(CGFloat)height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, (CGFloat)width, (CGFloat)height), cgImage);
    CGContextRelease(context);
    
    // Convert color values [0..255] to floats [0.0..1.0]
    CGFloat red   = (CGFloat)pixelData[0] / 255.0f;
    CGFloat green = (CGFloat)pixelData[1] / 255.0f;
    CGFloat blue  = (CGFloat)pixelData[2] / 255.0f;
    CGFloat alpha = (CGFloat)pixelData[3] / 255.0f;
    return [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (NSMutableArray<NSNumber *> *)lightness {
    NSMutableArray<NSNumber *> *arrReturn = [[NSMutableArray<NSNumber *> alloc] init];
    return arrReturn;
}



- (CGImageRef)CGImage {
    CGImageRef img = (__bridge CGImageRef)objc_getAssociatedObject(self, @selector(CGImage));
    if (self && NULL == img) {
        NSData *data = [self TIFFRepresentation];
        if (data) {
            CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
            img = CGImageSourceCreateImageAtIndex(source, 0, NULL);
            CFRelease(source);
            objc_setAssociatedObject(self, @selector(CGImage), CFBridgingRelease(img), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    return img;
}

@end

#pragma mark - GIF Decode

static inline void animated_gif_swizzleSelector(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    if (class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static BOOL AnimatedGifDataIsValid(NSData *data) {
    if (data.length > 4) {
        const unsigned char *bytes = [data bytes];
        return bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46;
    }
    return NO;
}

@implementation NSImage (AnimatedGIFImage)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            animated_gif_swizzleSelector(self, @selector(initWithData:), @selector(animated_gif_initWithData:));
        }
    });
}

- (instancetype)animated_gif_initWithData:(NSData *)data __attribute__((objc_method_family(init))) {
    if (AnimatedGifDataIsValid(data)) {
        self.data = data;
        
        CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)data, NULL);
        
        size_t count = CGImageSourceGetCount(source);
        NSMutableArray<NSImage *> *arrFrames = [NSMutableArray arrayWithCapacity:count];
        
        NSTimeInterval calculatedDuration = 0.0f;
        for (size_t i = 0; i < count; i ++) {
            CGImageRef img = CGImageSourceCreateImageAtIndex(source, i, NULL);
            NSSize size = NSSizeFromCGSize(CGSizeMake(CGImageGetWidth(img), CGImageGetHeight(img)));
            NSImage *image = [[NSImage alloc] initWithCGImage:img size:size];
            
            NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
            calculatedDuration += [[[properties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDictionary] objectForKey:(__bridge  NSString *)kCGImagePropertyGIFDelayTime] doubleValue];
            CGImageRelease(img);
            [arrFrames addObject:image];
        }
        CFRelease(source);
        self.duration = calculatedDuration;
        self.gifFrames = arrFrames;
    }
    return [self animated_gif_initWithData:data];
}

- (void)setData:(NSData *)data {
    objc_setAssociatedObject(self, @selector(data), data, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSData *)data {
    return objc_getAssociatedObject(self, @selector(data));
}

- (void)setDuration:(NSTimeInterval)duration {
    objc_setAssociatedObject(self, @selector(duration), @(duration), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)duration {
    return [objc_getAssociatedObject(self, @selector(duration)) doubleValue];
//    NSLog(@"%@", aa);
//    return [objc_getAssociatedObject(self, @selector(duration)) doubleValue];
}

- (void)setGifFrames:(NSMutableArray<NSImage *> *)gifFrames {
    objc_setAssociatedObject(self, @selector(gifFrames), gifFrames, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray<NSImage *> *)gifFrames {
    return objc_getAssociatedObject(self, @selector(gifFrames));
}

@end

#pragma mark - GIF Frames Encode

NSString * const GIFFrameEncodeDomain = @"com.pic2char.gifEncoder.error";

@implementation NSArray (AnimatedGIFFrame)

- (NSData *)dataOfGifFramesWithDuration:(NSTimeInterval) duration {
    NSAssert([self isKindOfClass:[NSArray<NSImage *> class]], @"Encode images to GIF-Data neet kind of class instance (NSArray<NSImage *> *)! Please check Objects in array.");
    if (![self isKindOfClass:[NSArray<NSImage *> class]]) {
        return nil;
    }
    
    // 1. 数据准备
    size_t frameCount = self.count;
    NSUInteger loopCount = 0;
    NSTimeInterval frameDuration = duration / frameCount;
    // 每帧的属性
    NSDictionary *frameProperties = @{
                                      (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                              (__bridge NSString *)kCGImagePropertyGIFDelayTime: @(frameDuration)
                                              }
                                      };
    
    // 2. 创建图片 destination
    NSMutableData *mutableData = [NSMutableData data];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, kUTTypeGIF, frameCount, NULL);
    NSDictionary *imageProperties = @{
                                      (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                              (__bridge NSString *)kCGImagePropertyGIFLoopCount: @(loopCount)
                                              }
                                      };
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)imageProperties);
    
    // 3. 将每帧写入图片 destination
    for (int idx = 0; idx < frameCount; idx ++) {
        CGImageDestinationAddImage(destination, [[self objectAtIndex:idx] CGImage], (__bridge CFDictionaryRef)frameProperties);
    }
    
    // 4. 结束编辑
    BOOL success = CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    if (!success) {
        NSError *error = [NSError errorWithDomain:GIFFrameEncodeDomain code:-1 userInfo:@{
                                                                                          NSLocalizedDescriptionKey : NSLocalizedString(@"Could not finalize image destination", nil)
                                                                                          }];
        NSLog(@"%@", error);
        return nil;
    }
    
    return [NSData dataWithData:mutableData];
}

@end
