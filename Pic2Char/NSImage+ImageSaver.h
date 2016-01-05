//
//  NSImage+ImageSaver.h
//  Pic2Char
//
//  Created by 海底捞lzx on 15/12/25.
//  Copyright © 2015年 海底捞. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (ImageSaver)

- (BOOL)saveImageToURL:(NSURL *)url;

@end
