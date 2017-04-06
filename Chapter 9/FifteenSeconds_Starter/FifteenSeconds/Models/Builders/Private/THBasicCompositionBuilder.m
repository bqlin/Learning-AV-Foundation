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

#import "THBasicCompositionBuilder.h"
#import "THBasicComposition.h"
#import "THFunctions.h"

@interface THBasicCompositionBuilder ()
@property (strong, nonatomic) THTimeline *timeline;
@property (strong, nonatomic) AVMutableComposition *composition;
@end

@implementation THBasicCompositionBuilder

- (id)initWithTimeline:(THTimeline *)timeline {
    self = [super init];
    if (self) {
        _timeline = timeline;
    }
    return self;
}

- (id <THComposition>)buildComposition {
	// bq
	// 初始化
	self.composition = [AVMutableComposition composition];
	
	[self addCompositionTrackOfType:AVMediaTypeVideo withMediaItems:self.timeline.videos];
	[self addCompositionTrackOfType:AVMediaTypeAudio withMediaItems:self.timeline.voiceOvers];
	[self addCompositionTrackOfType:AVMediaTypeAudio withMediaItems:self.timeline.musicItems];
	
	// 创建并返回基本的 composition
	THBasicComposition *basicComposition = [THBasicComposition compositionWithComposition:self.composition];
    return basicComposition;
}

/// 创建轨道内容
- (void)addCompositionTrackOfType:(NSString *)mediaType
                   withMediaItems:(NSArray *)mediaItems {
    // bq
	if (!THIsEmpty(mediaItems)) { // 数组不为空
		CMPersistentTrackID trackID = kCMPersistentTrackID_Invalid;
		
		AVMutableCompositionTrack *compositionTack = [self.composition addMutableTrackWithMediaType:mediaType preferredTrackID:trackID]; // 轨道ID将自动分配
		
		// 创建一个为 kCMTimeZero 常量的 CMTime 对象，将其作为插入光标的时间
		CMTime cursorTime = kCMTimeZero;
		for (THMediaItem *item in mediaItems) {
			if (CMTIME_COMPARE_INLINE(item.startTimeInTimeline, !=, kCMTimeInvalid)) { // 有效，不允许剪辑有间隙
				cursorTime = item.startTimeInTimeline;
			}
			
			AVAssetTrack *assetTrack = [[item.asset tracksWithMediaType:mediaType] firstObject];
			NSError *error;
			[compositionTack insertTimeRange:item.timeRange ofTrack:assetTrack atTime:cursorTime error:&error];
			
			// 下一次循环迭代的光标时间为当前轨道后面
			cursorTime = CMTimeAdd(cursorTime, item.timeRange.duration);
		}
	}
    
}

@end
