//
//  LZXCharImg.h
//  Pic2Char
//
//  Created by 海底捞lzx on 15/12/12.
//  Copyright © 2015年 海底捞. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LZXCharImg : NSObject

@property (nonatomic, strong, nullable) NSData *data;

+ (nonnull instancetype)sharedCharImg;

- (nonnull NSImage *)charsImageWithImage:(nonnull NSImage *)imgOriginal;

@end
