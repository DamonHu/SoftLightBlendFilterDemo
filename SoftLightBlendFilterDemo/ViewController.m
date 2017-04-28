//
//  ViewController.m
//  SoftLightBlendFilterDemo
//
//  Created by Damon on 2017/4/28.
//  Copyright © 2017年 damon. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import "GPUImageBeautifyFilter.h"
#import "DSoftLightBlendFilter.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()
{
    //摄像头
    GPUImageVideoCamera *m_videoCamera;
    GPUImageView *m_filteredVideoView;
    
    //录制
    GPUImageMovieWriter *m_movieWriter;
    NSMutableDictionary * videoSettings; //视频设置
    NSDictionary * audioSettings; //声音设置
    
    //滤镜
    GPUImageBrightnessFilter *m_brightnewssFilter;  //光度
    GPUImageExposureFilter *m_exposureFilter;       //曝光
    GPUImageContrastFilter *m_contrastFilter;       //对比度
    GPUImageSaturationFilter *m_saturationFilter;   //饱和度
    

    DSoftLightBlendFilter *m_softLightBlendFilter;  //柔光
    GPUImageBeautifyFilter *beautifyFilter; //美颜
    
    //滤镜组
    GPUImageFilterGroup *filterGroup;
    
    //拍摄路径
    NSString* videoPath;
    //播放器
    MPMoviePlayerController *playerController;
    
    //label
    UILabel *timeLabel;
    float time;
    NSTimer *timer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initCamere];
    //录制按钮
    UIButton* m_RecordBtn = [[UIButton alloc] initWithFrame:CGRectMake(250, 400, 100, 100)];
    [m_RecordBtn setImage:[UIImage imageNamed:@"home_video_start"] forState:UIControlStateNormal];
    [self.view addSubview:m_RecordBtn];
    [m_RecordBtn addTarget:self action:@selector(recordVideo) forControlEvents:UIControlEventTouchUpInside];
    
    //播放按钮
    UIButton* m_PlayBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 400, 100, 100)];
    [m_PlayBtn setImage:[UIImage imageNamed:@"resume_play"] forState:UIControlStateNormal];
    [self.view addSubview:m_PlayBtn];
    [m_PlayBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    
    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 50, 300, 40)];
    [timeLabel setTextColor:[UIColor redColor]];
    [timeLabel setText:@"点击红色按钮开始拍摄"];
    [self.view addSubview:timeLabel];
}

-(void)initCamere{
    m_filteredVideoView = [[GPUImageView alloc] initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
    
    // Add the view somewhere so it's visible
    [self.view addSubview:m_filteredVideoView];
    
    m_videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
    //前置摄像头
    m_videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    m_videoCamera.horizontallyMirrorRearFacingCamera = NO;
    m_videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    [m_videoCamera addAudioInputsAndOutputs];
    
    //光度
    m_brightnewssFilter = [[GPUImageBrightnessFilter alloc] init];
    [m_brightnewssFilter setBrightness:0.0f];
    //曝光
    m_exposureFilter = [[GPUImageExposureFilter alloc] init];
    [m_exposureFilter setExposure:0.0f];
    //对比度
    m_contrastFilter = [[GPUImageContrastFilter alloc] init];
    [m_contrastFilter setContrast:1.0f];
    //饱和度
    m_saturationFilter = [[GPUImageSaturationFilter alloc] init];
    [m_saturationFilter setSaturation:1.0f];
    
    //美颜程度0.5
    beautifyFilter = [[GPUImageBeautifyFilter alloc] initWithDegree:0.5];
    
    //柔光
    m_softLightBlendFilter = [[DSoftLightBlendFilter alloc] init];
    
    filterGroup = [[GPUImageFilterGroup alloc] init];
    [filterGroup addFilter:m_brightnewssFilter];
    [filterGroup addFilter:m_exposureFilter];
    [filterGroup addFilter:m_contrastFilter];
    [filterGroup addFilter:m_saturationFilter];
    [filterGroup addFilter:beautifyFilter];
    [filterGroup addFilter:m_softLightBlendFilter];
    
    //先后顺序
    [m_brightnewssFilter addTarget:m_exposureFilter];
    [m_exposureFilter addTarget:m_contrastFilter];
    [m_contrastFilter addTarget:m_saturationFilter];
    [m_saturationFilter addTarget:beautifyFilter];
    [beautifyFilter addTarget:m_softLightBlendFilter];
    
    [filterGroup setInitialFilters:[NSArray arrayWithObject:m_brightnewssFilter]];
    [filterGroup setTerminalFilter:m_softLightBlendFilter];
    
    [filterGroup addTarget:m_filteredVideoView];
    [m_videoCamera addTarget:filterGroup];

    [m_videoCamera startCameraCapture];

}
-(void)recordVideo{
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(changeProgress) userInfo:nil repeats:YES];
    
    videoPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie4.mov"];
    unlink([videoPath UTF8String]); // 如果已经存在文件，AVAssetWriter会有异常，删除旧文件
    NSURL *movieURL = [NSURL fileURLWithPath:videoPath];
    //视频设置
    videoSettings = [[NSMutableDictionary alloc] init];
    [videoSettings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    [videoSettings setObject:[NSNumber numberWithInteger:720] forKey:AVVideoWidthKey]; //视频的宽度,这里最好是定义imageCamera时候的宽度
    [videoSettings setObject:[NSNumber numberWithInteger:1280] forKey:AVVideoHeightKey]; //视频的高度.同上
    
    //音频设置
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                     [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                     [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                     [ NSNumber numberWithFloat: 16000.0 ], AVSampleRateKey,
                     [ NSData dataWithBytes:&channelLayout length: sizeof( AudioChannelLayout ) ], AVChannelLayoutKey,
                     [ NSNumber numberWithInt: 32000 ], AVEncoderBitRateKey,
                     nil];
    
    m_movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720, 1280) fileType:AVFileTypeQuickTimeMovie outputSettings:videoSettings];
    //    [m_movieWriter setHasAudioTrack:YES audioSettings:audioSettings];
    [m_movieWriter setHasAudioTrack:true];
    m_videoCamera.audioEncodingTarget = m_movieWriter; //设置声音
    m_movieWriter.encodingLiveVideo = YES;
    
    //写入加上滤镜
    [filterGroup addTarget:m_movieWriter];
    
    [m_movieWriter startRecording];
}

-(void)changeProgress{
    time= time+0.1;
    [timeLabel setText:[NSString stringWithFormat:@"拍摄时长:%.2f",time]];
}

-(void)playVideo{
    if (!videoPath) {
        NSLog(@"请先录制视频");
        return;
    }
    if (timer) {
        [timer invalidate];
        timer == nil;
    }
    [m_movieWriter finishRecording];
    [filterGroup removeTarget:m_movieWriter];
    m_videoCamera.audioEncodingTarget = nil;
    
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    playerController = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
    
    [playerController.view setFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
    
    [playerController.view setAlpha:1.0];
    [playerController setControlStyle:MPMovieControlStyleNone];
    [playerController setRepeatMode:MPMovieRepeatModeNone];
    [playerController setShouldAutoplay:YES];
    [playerController prepareToPlay];
    [self.view addSubview:playerController.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
