//
//  ViewController.m
//  ICGVideoTrimmer
//
//  Created by HuongDo on 1/15/15.
//  Copyright (c) 2015 ichigo. All rights reserved.
//

#import "ViewController.h"
#import "ICGVideoTrimmerView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "MKOVideoMerge/MKOVideoMerge.h"
#import <AssetsLibrary/ALAsset.h>
#import "SegmentedExtension/UISegmentedControl+WithoutBorder.h"
#import "CustomView/YView.h"
#import "Utility.h"

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, ICGVideoTrimmerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *endTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *indicatorView;
@property (weak, nonatomic) IBOutlet UIButton *startPosButton;
@property (weak, nonatomic) IBOutlet UIButton *endPosButton;
@property (weak, nonatomic) IBOutlet UIView *startEndContainer;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (assign, nonatomic) BOOL isPlaying;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) NSTimer *playbackTimeCheckerTimer;
@property (assign, nonatomic) CGFloat videoPlaybackPosition;

@property (weak, nonatomic) IBOutlet ICGVideoTrimmerView *trimmerView;
@property (weak, nonatomic) IBOutlet UIButton *trimButton;
@property (weak, nonatomic) IBOutlet UIView *videoPlayer;
@property (weak, nonatomic) IBOutlet UIView *videoLayer;

@property (strong, nonatomic) NSString *tempVideoPath;
@property (strong, nonatomic) NSString *tempVideoPath1;

@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (strong, nonatomic) AVAsset *asset;

@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat stopTime;

@property (assign, nonatomic) BOOL restartOnPlay;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    YView *view = [[YView alloc] initWithFrame:CGRectMake((CGRectGetMidX(self.view.frame)-20)/2, (CGRectGetMaxY(self.view.frame)-CGRectGetHeight(self.trimmerView.frame)-CGRectGetHeight(self.startEndContainer.frame)/2 -30)/2,40, CGRectGetHeight(self.trimmerView.frame)+CGRectGetHeight(self.startEndContainer.frame)/2)];
    NSLog(@"YView %@",NSStringFromCGRect(view.frame));
    [self.view addSubview:view];
    [self.view bringSubviewToFront:view];
    
    self.endTimeLabel.text = [Utility secondToTimeFormat:CMTimeGetSeconds([self.asset duration])];
    [self.endPosButton setImage:[UIImage imageNamed:@"end_here_after_press_2"] forState:UIControlStateNormal];
    self.endPosButton.enabled  = false;

    
    [self loadVideoView];
    [self.segmentedControl removeBorder];
    self.tempVideoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpMov.mov"];
    self.tempVideoPath1 = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tmpMov1.mov"];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - SegmentedControlAction

- (IBAction)doneButtonAction:(id)sender {
    if (self.segmentedControl.selectedSegmentIndex) {
        [self trimVideoFromStartPos];
    }else{
        [self trimVideo];
    }

}

#pragma mark - ICGVideoTrimmerDelegate

- (IBAction)endButtonAction:(id)sender {
    [self.trimmerView setPointEnd];

}
- (IBAction)startButtonAction:(id)sender {
    
        [self.trimmerView setPointStart];

}
- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime
{
    _restartOnPlay = YES;
    [self.player pause];
    self.isPlaying = NO;
    [self stopPlaybackTimeChecker];

    [self.trimmerView hideTracker:true];

    if (startTime != self.startTime) {
        //then it moved the left position, we should rearrange the bar
        [self seekVideoToPos:startTime];
    }
    else{ // right has changed
        [self seekVideoToPos:endTime];
    }
//    NSLog(@"start time %.3f end time %.3f",startTime,endTime);
    self.startTime = startTime;
    self.stopTime = endTime;
    
    self.startTimeLabel.text =  [Utility secondToTimeFormat:startTime];
;
    self.endTimeLabel.text = [Utility secondToTimeFormat:endTime];

}

-(void)disableSeekPosControl:(NSDictionary*)infoDict{
    
    CGFloat leftOverlayOriginX = [[infoDict valueForKey:@"lefttOverlayViewOrigin"] floatValue];
    CGFloat rightOverlayOriginX = [[infoDict valueForKey:@"rightOverlayViewOrigin"] floatValue];
    CGFloat contentOffsetX = [[infoDict valueForKey:@"contentOffset"] floatValue];
    CGFloat currentPosition = [[infoDict valueForKey:@"currentPosition"] floatValue];
    self.currentTimeLabel.text = [Utility secondToTimeFormat:currentPosition];
    [self seekVideoToPos:currentPosition];
    if (contentOffsetX+CGRectGetWidth([UIScreen mainScreen].bounds)/2 >=  rightOverlayOriginX){
        [self.startPosButton setImage:[UIImage imageNamed:@"end_here_after_press"] forState:UIControlStateNormal];
        self.startPosButton.enabled  = false;
    }else if(contentOffsetX+CGRectGetWidth([UIScreen mainScreen].bounds)/2 <=  leftOverlayOriginX){
        [self.endPosButton setImage:[UIImage imageNamed:@"end_here_after_press_2"] forState:UIControlStateNormal];
        self.endPosButton.enabled  = false;
    }else{
        [self.startPosButton setImage:[UIImage imageNamed:@"end_here"] forState:UIControlStateNormal];
        self.startPosButton.enabled  = true;
        [self.endPosButton setImage:[UIImage imageNamed:@"end_here_2"] forState:UIControlStateNormal];
        self.endPosButton.enabled  = true;


    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *sampleZvideoFilePath = [[NSBundle mainBundle] pathForResource:@"SampleVideo" ofType:@"mp4"];
    NSURL *url =[NSURL fileURLWithPath:sampleZvideoFilePath];
    self.asset = [AVAsset assetWithURL:url];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
    
    self.player = [AVPlayer playerWithPlayerItem:item];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [self.videoLayer.layer addSublayer:self.playerLayer];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnVideoLayer:)];
    [self.videoLayer addGestureRecognizer:tap];
    
    self.videoPlaybackPosition = 0;

    [self tapOnVideoLayer:tap];
    
    // set properties for trimmer view
    [self.trimmerView setThemeColor:[UIColor lightGrayColor]];
    [self.trimmerView setAsset:self.asset];
    [self.trimmerView setShowsRulerView:NO];
    [self.trimmerView setRulerLabelInterval:10];
    [self.trimmerView setTrackerColor:[UIColor cyanColor]];
    [self.trimmerView setDelegate:self];
    
    // important: reset subviews
    [self.trimmerView resetSubviews];
    
    [self.trimButton setHidden:NO];
}


-(void)loadVideoView{
    NSString *sampleZvideoFilePath = [[NSBundle mainBundle] pathForResource:@"SampleVideo" ofType:@"mp4"];
    NSURL *url =[NSURL fileURLWithPath:sampleZvideoFilePath];
    self.asset = [AVAsset assetWithURL:url];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];
    
    self.player = [AVPlayer playerWithPlayerItem:item];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [self.videoLayer.layer addSublayer:self.playerLayer];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnVideoLayer:)];
    [self.videoLayer addGestureRecognizer:tap];
    
    self.videoPlaybackPosition = 0;
    
    [self tapOnVideoLayer:tap];
    
    // set properties for trimmer view
    [self.trimmerView setThemeColor:[UIColor lightGrayColor]];
    [self.trimmerView setAsset:self.asset];
    [self.trimmerView setShowsRulerView:YES];
    [self.trimmerView setRulerLabelInterval:10];
    [self.trimmerView setTrackerColor:[UIColor cyanColor]];
    [self.trimmerView setDelegate:self];
    
    // important: reset subviews
    [self.trimmerView resetSubviews];
    
    [self.trimButton setHidden:NO];

}

#pragma mark - Actions

- (void)deleteTempFile:(NSString*)videoFilePath
{
    NSURL *url = [NSURL fileURLWithPath:videoFilePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    NSError *err;
    if (exist) {
        [fm removeItemAtURL:url error:&err];
        NSLog(@"file deleted");
        if (err) {
            NSLog(@"file remove error, %@", err.localizedDescription );
        }
    } else {
        NSLog(@"no file by that name");
    }
}



- (IBAction)selectAsset:(id)sender
{
    UIImagePickerController *myImagePickerController = [[UIImagePickerController alloc] init];
    myImagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
    myImagePickerController.mediaTypes =
    [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    myImagePickerController.delegate = self;
    myImagePickerController.editing = NO;
    [self presentViewController:myImagePickerController animated:YES completion:nil];
}


#pragma mark - Cut Video Actions

- (void)trimVideoFromStartPos
{
    [self deleteTempFile:self.tempVideoPath];
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.asset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:self.asset presetName:AVAssetExportPresetPassthrough];
        // Implementation continues.
        
        NSURL *furl = [NSURL fileURLWithPath:self.tempVideoPath];
        
        self.exportSession.outputURL = furl;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        CMTime start = CMTimeMakeWithSeconds(0.0, self.asset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(self.startTime-0.0, self.asset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    
                    NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    
                    NSLog(@"Export canceled");
                    break;
                default:
                    NSLog(@"NONE");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [Utility showProgressHUD:self.view];
                        NSURL *movieUrl = [NSURL fileURLWithPath:self.tempVideoPath];
                    });
                    [self trimEndVideoEndPos];
                    break;
            }
        }];
        
    }
}

-(void)trimEndVideoEndPos{
    [self deleteTempFile:self.tempVideoPath1];
    
    self.exportSession = [[AVAssetExportSession alloc]
                          initWithAsset:self.asset presetName:AVAssetExportPresetPassthrough];
    // Implementation continues.
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    NSString *outputURL = paths[0];
    //    NSFileManager *manager = [NSFileManager defaultManager];
    //    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    //    outputURL = [outputURL stringByAppendingPathComponent:@"output.mp4"];
    //    // Remove Existing File
    //    [manager removeItemAtPath:outputURL error:nil];
    //    NSURL *furl = [NSURL fileURLWithPath:outputURL];
    
    self.exportSession.outputURL = [NSURL fileURLWithPath:self.tempVideoPath1];
    self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    
    CMTime end = CMTimeMakeWithSeconds(self.stopTime, self.asset.duration.timescale);
    CMTime endduration = CMTimeMakeWithSeconds(self.asset.duration.timescale-0.0, self.asset.duration.timescale);
    CMTimeRange endrange = CMTimeRangeMake(end, endduration);
    self.exportSession.timeRange = endrange;
    
    
    [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        switch ([self.exportSession status]) {
            case AVAssetExportSessionStatusFailed:
                
                NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                break;
            case AVAssetExportSessionStatusCancelled:
                
                NSLog(@"Export canceled");
                break;
            default:
                NSLog(@"NONE");
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    NSURL *movieUrl = [NSURL fileURLWithPath:self.tempVideoPath1];
                    NSLog(@"movieUrl %@ %@",movieUrl.relativePath,self.tempVideoPath1);
                    //                    UISaveVideoAtPathToSavedPhotosAlbum([movieUrl relativePath], self,nil, nil);
                    
                });
                [self mergeVideosForCut];
                
                break;
        }
    }];
    
}

-(void)mergeVideosForCut
{
    
    [MKOVideoMerge mergeVideoFiles:@[[NSURL fileURLWithPath:self.tempVideoPath],[NSURL fileURLWithPath:self.tempVideoPath1]] completion:^(NSURL *mergedVideoFile, NSError *error) {
        NSLog(@"mergedVideoFile %@",mergedVideoFile);
        if (error) {
            NSString *errorMessage = [NSString stringWithFormat:@"Could not merge videos: %@", [error localizedDescription]];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        //
        UISaveVideoAtPathToSavedPhotosAlbum([mergedVideoFile relativePath], self,@selector(video:didFinishSavingWithError:contextInfo:), nil);
    }];
    
}

#pragma mark - Trim Video Actions

- (void)trimVideo
{
    [self deleteTempFile:self.tempVideoPath];
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:self.asset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:self.asset presetName:AVAssetExportPresetPassthrough];
        // Implementation continues.
        
        NSURL *furl = [NSURL fileURLWithPath:self.tempVideoPath];
        
        self.exportSession.outputURL = furl;
        self.exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        CMTime start = CMTimeMakeWithSeconds(self.startTime, self.asset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(self.stopTime - self.startTime, self.asset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            
            switch ([self.exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    
                    NSLog(@"Export failed: %@", [[self.exportSession error] localizedDescription]);
                    break;
                case AVAssetExportSessionStatusCancelled:
                    
                    NSLog(@"Export canceled");
                    break;
                default:
                    NSLog(@"NONE");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [Utility showProgressHUD:self.view];
                        NSURL *movieUrl = [NSURL fileURLWithPath:self.tempVideoPath];
                        UISaveVideoAtPathToSavedPhotosAlbum([movieUrl relativePath], self,@selector(video:didFinishSavingWithError:contextInfo:), nil);
                    });
                    
                    break;
            }
        }];
        
    }
}


- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    [Utility hidProgressHUD:self.view];
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}



- (void)viewDidLayoutSubviews
{
    self.playerLayer.frame = CGRectMake(0, 0, self.videoLayer.frame.size.width, self.videoLayer.frame.size.height);
}

- (void)tapOnVideoLayer:(UITapGestureRecognizer *)tap
{
    if (self.isPlaying) {
        [self.player pause];
        [self stopPlaybackTimeChecker];
    }else {
        if (_restartOnPlay){
            [self seekVideoToPos: self.startTime];
            [self.trimmerView seekToTime:self.startTime];
            _restartOnPlay = NO;
        }
        [self.player play];
        [self startPlaybackTimeChecker];
    }
    self.isPlaying = !self.isPlaying;
    [self.trimmerView hideTracker:!self.isPlaying];
}

- (void)startPlaybackTimeChecker
{
    [self stopPlaybackTimeChecker];
    
    self.playbackTimeCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(onPlaybackTimeCheckerTimer) userInfo:nil repeats:YES];
}

- (void)stopPlaybackTimeChecker
{
    if (self.playbackTimeCheckerTimer) {
        [self.playbackTimeCheckerTimer invalidate];
        self.playbackTimeCheckerTimer = nil;
    }
}

#pragma mark - PlaybackTimeCheckerTimer

- (void)onPlaybackTimeCheckerTimer
{
    CMTime curTime = [self.player currentTime];
    Float64 seconds = CMTimeGetSeconds(curTime);
    if (seconds < 0){
        seconds = 0; // this happens! dont know why.
    }
    self.videoPlaybackPosition = seconds;

    [self.trimmerView seekToTime:seconds];
    
    if (self.videoPlaybackPosition >= self.stopTime) {
        self.videoPlaybackPosition = self.startTime;
        [self seekVideoToPos: self.startTime];
        [self.trimmerView seekToTime:self.startTime];
    }
}

- (void)seekVideoToPos:(CGFloat)pos
{
    self.videoPlaybackPosition = pos;
    CMTime time = CMTimeMakeWithSeconds(self.videoPlaybackPosition,20);
    NSLog(@"seekVideoToPos time:%.2f %.2d", CMTimeGetSeconds(time),self.player.currentTime.timescale);
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

@end
