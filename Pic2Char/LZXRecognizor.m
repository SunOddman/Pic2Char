//
//  LZXRecognizor.m
//  Pic2Char
//
//  Created by 海底捞lzx on 15/12/12.
//  Copyright © 2015年 海底捞. All rights reserved.
//

#import "LZXRecognizor.h"

@interface LZXRecognizor (){
    char charset[200];
    int lengthCharset;    
}


@end

@implementation LZXRecognizor

- (void)initCharset {
    for (int i = 33; i < 127; i ++, lengthCharset ++) {
        charset[lengthCharset] = i;
    }
    for (int i = 161; i < 255; i ++, lengthCharset ++) {
        charset[lengthCharset] = i;
    }
    NSLog(@"lenght = %d", lengthCharset);
    for (int i = 0; i < lengthCharset; i ++) {
        NSLog(@"%c", charset[i]);
    }
}

@end
