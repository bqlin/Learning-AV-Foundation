//
//  MIT License
//
//  Copyright (c) 2014 Bob McCune http://bobmccune.com/
//  Copyright (c) 2014 TapHarmonic, LLC http://tapharmonic.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "THCompositionExporter.h"
#import "UIAlertView+THAdditions.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface THCompositionExporter ()
@property (strong, nonatomic) id <THComposition> composition;
@property (strong, nonatomic) AVAssetExportSession *exportSession;
@end

@implementation THCompositionExporter

- (instancetype)initWithComposition:(id <THComposition>)composition {

    self = [super init];
    if (self) {
        _composition = composition;
    }
    return self;
}

- (void)beginExport {
    // Bq
	// 创建一个组合的可导出版本
	self.exportSession = [self.composition makeExportable];
	self.exportSession.outputURL = [self exportURL];
	self.exportSession.outputFileType = AVFileTypeMPEG4;
	
	[self.exportSession exportAsynchronouslyWithCompletionHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			AVAssetExportSessionStatus status = self.exportSession.status;
			if (status == AVAssetExportSessionStatusCompleted) {
				[self writeExportedVideoToAssetsLibrary];
			} else {
				[UIAlertView showAlertWithTitle:@"导出失败" message:@"请求导出失败。"];
			}
		});
	}];
	
	self.exporting = YES;
	[self monitorExportProgress];
}

/// 监视导出过程
- (void)monitorExportProgress {
	// bq
	double delayInSeconds = 0.1;
	int64_t delta = (int64_t)(delayInSeconds * NSEC_PER_SEC);	// ! 此处加了括号
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delta);
	
	dispatch_after(popTime, dispatch_get_main_queue(), ^{
		AVAssetExportSessionStatus stauts = self.exportSession.status;
		if (stauts ==  AVAssetExportSessionStatusExporting) {
			self.progress = self.exportSession.progress;
			[self monitorExportProgress];	// 递归回调
		} else {
			self.exporting = NO;
		}
	});
}

/// 把导出的文件写入 Asset Laibrary
- (void)writeExportedVideoToAssetsLibrary {
	NSURL *exportURL = self.exportSession.outputURL;
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	
	if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportURL]) { // 检查要写入的内容是否可写入
		[library writeVideoAtPathToSavedPhotosAlbum:exportURL completionBlock:^(NSURL *assetURL, NSError *error) {	// 调用该方法会弹出询问用户是否允许访问相册
			if (error) {
				NSString *message = @"Unable to write ro Photos library.";
				[UIAlertView showAlertWithTitle:@"写入失败" message:message];
			} else {
				NSLog(@"导出成功！");
			}
			[[NSFileManager defaultManager] removeItemAtURL:exportURL error:nil];
		}];
	}else{
		NSLog(@"视频无法导出到媒体库。");
	}
    
}

- (NSURL *)exportURL {
    NSString *filePath = nil;
    NSUInteger count = 0;
    do {
        filePath = NSTemporaryDirectory();
        NSString *numberString = count > 0 ?
            [NSString stringWithFormat:@"-%li", (unsigned long) count] : @"";
        NSString *fileNameString =
            [NSString stringWithFormat:@"Masterpiece-%@.m4v", numberString];
        filePath = [filePath stringByAppendingPathComponent:fileNameString];
        count++;
    } while ([[NSFileManager defaultManager] fileExistsAtPath:filePath]);

    return [NSURL fileURLWithPath:filePath];
}

@end
