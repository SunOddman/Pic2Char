//
//  ViewController.m
//  Pic2Char
//
//  Created by 海底捞lzx on 15/12/11.
//  Copyright © 2015年 海底捞. All rights reserved.
//

#import "ViewController.h"
#import "LZXCharImg.h"
#import "NSImage+ImageSaver.h"

@interface ViewController ()

@property (weak) IBOutlet NSTextField *textfiledPicPath;
@property (weak) IBOutlet NSPathControl *pathView;
@property (weak) IBOutlet NSImageView *imgOriginal;
@property (weak) IBOutlet NSImageView *imgOutput;

@property (nonatomic, copy) NSURL *picPath;
@property (nonatomic, strong) NSImage *original;

@end
@implementation ViewController

#pragma mark - export
- (IBAction)exportClick:(NSButton *)sender {
    
    if (!self.picPath) {
        return;
    }
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setAllowedFileTypes:@[@"png", @"gif", @"jpg", @"jpeg", @"GIF"]];
    [savePanel setNameFieldStringValue:[self.picPath lastPathComponent]];
    [savePanel setMessage:@"保存"];
    [savePanel setExtensionHidden:NO];
    [savePanel setCanCreateDirectories:YES];

    if ([savePanel runModal] == NSModalResponseOK) {
        NSURL *url = [savePanel URL];
        [self.imgOutput.image saveImageToURL:url];
    } else {
        
    }
}

#pragma mark - import
- (IBAction)pickPictureAction:(NSButton *)sender {
    NSOpenPanel *picturePicker = [NSOpenPanel openPanel];
    [picturePicker setAllowedFileTypes:@[@"png", @"gif", @"jpg", @"jpeg", @"GIF"]];
    [picturePicker setAllowsMultipleSelection:NO];
    [picturePicker setCanChooseDirectories:NO];
    if ([picturePicker runModal] == NSModalResponseOK) {
        self.picPath = picturePicker.URL;
    } else {
        self.picPath = nil;
    }
}

#pragma mark - setter
- (void)setPicPath:(NSURL *)picPath {
    _picPath = picPath;
    if (!picPath) {
        return;
    }
    self.textfiledPicPath.stringValue = picPath.relativePath;
    self.pathView.URL = picPath;
    
    NSData *data = [NSData dataWithContentsOfFile:[picPath path]];
    
    self.original = [[NSImage alloc] initWithData:data];
    self.imgOriginal.image = self.original;
    
    [self pic2Char];
}

#pragma mark - view
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, 960, 540);
    self.textfiledPicPath.textColor = [NSColor blackColor];
    self.textfiledPicPath.hidden = YES;
    self.pathView.editable = NO;
    // Do any additional setup after loading the view.
    
}

#pragma mark - Pic 2 Char

- (void)pic2Char {
//    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
//        NSLog(@"%@", [NSThread currentThread]);
//        NSImage *img = [[LZXCharImg sharedCharImg] charsImageWithImage:self.original];
//    }];
//    [op setCompletionBlock:^{
//        NSLog(@"%@", [NSThread currentThread]);
//    }];
//    [op start];
//    self.imgOutput.image = [[LZXCharImg sharedCharImg] charsImageWithImage:self.original];
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSImage *img = [[LZXCharImg sharedCharImg] charsImageWithImage:self.original];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imgOutput.image = img;
        });
    });
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
