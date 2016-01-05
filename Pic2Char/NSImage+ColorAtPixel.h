//
//  NSImage+ColorAtPixel.h
//  Pic2Char
//
//  Created by 海底捞lzx on 15/12/18.
//  Copyright © 2015年 海底捞. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

@interface NSImage (ColorAtPixel)

@property (nonatomic, readonly, nullable) CGImageRef CGImage;

- (nonnull NSColor *)colorAtPixel:(CGPoint)point;

- (nullable CGImageRef)CGImage;

- (nullable UInt32 *)Colors;

- (NSUInteger)w;
- (NSUInteger)h;

@end

@interface NSImage (AnimatedGIFImage)

@property (nonatomic, nullable, copy) NSData *data;
@property (nonatomic, assign) NSTimeInterval duration;

@property (nullable, nonatomic, strong) NSMutableArray<NSImage *> *gifFrames;

@end

@interface NSArray (AnimatedGIFFrame)

- (nullable NSData *)dataOfGifFramesWithDuration:(NSTimeInterval) duration;

@end
