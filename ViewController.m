//
//  ViewController.m
//  Visual Audio
//
//  Created by Jose Pablo on 6/15/14.
//  Copyright (c) 2014 Audio Developments. All rights reserved.
//


#import "ViewController.h"
#import "TheAmazingAudioEngine.h"
#import "WaveformView.h"
#import "Waveform.h"

#define viewWidth 1024
#define viewhHeight 768
#define infoLabelYOffset 60

@interface ViewController ()
@property (nonatomic,strong) AEAudioController *audioController;
@property (nonatomic,strong) WaveformView *waveformView;
@property (nonatomic,strong) Waveform *viewWaveform;
@property (nonatomic,strong) UIButton *freezeButton;
@property (nonatomic,strong) UISwitch *typeSwitch;
@property (nonatomic) UILabel *infoLabel;
@property (nonatomic) AUDInt16Buffer buffer;
@property (nonatomic) NSUInteger bufferCapacity;
@property (nonatomic) BOOL frozen;
@end

@implementation ViewController
            
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewWaveform = [Waveform waveform];
    _bufferCapacity = 1024;
    AUDInt16Buffer buffer = { malloc(sizeof(SInt16)*_bufferCapacity), 0};
    _buffer = buffer;
    _frozen=NO;
    
    self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleaved16BitStereoAudioDescription] inputEnabled:YES];
    [_audioController start:NULL];

    AEBlockAudioReceiver *receiver = [AEBlockAudioReceiver audioReceiverWithBlock:
                                    ^(void                     *source,
                                      const AudioTimeStamp     *time,
                                      UInt32                    frames,
                                      AudioBufferList          *audio) {
                                            SInt16 *sample=(SInt16*)audio->mBuffers[0].mData;
                                            for (int i=0; i<frames; i++)
                                            {
                                                if (_frozen) break;
                                                _buffer.samples[_buffer.length]=sample[i];
                                                _buffer.length++;
                                                if (_buffer.length==_bufferCapacity)
                                                {
                                                    waveformCopyBuffer(_viewWaveform, _buffer);
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [_waveformView drawWaveform];
                                                    });
                                                    _buffer.length = 0;
                                                }
                                            }
                                        }
                                    ];
    
    [_audioController addInputReceiver:receiver];
    
    self.freezeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 125, 50)];
    _freezeButton.center = CGPointMake(viewWidth/2, viewhHeight/14);
    [_freezeButton addTarget:self action:@selector(handleFreezeButton:) forControlEvents:UIControlEventTouchUpInside];
    [_freezeButton setTitle:@"Freeze" forState:UIControlStateNormal];
    _freezeButton.titleLabel.font = [UIFont fontWithName:@"Arial" size:22];
    [_freezeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    
    self.typeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 125, 125)];
    _typeSwitch.center = CGPointMake(viewWidth*11/12, viewhHeight/14);
    [_typeSwitch addTarget:self action:@selector(handleTypeSwitch:) forControlEvents:UIControlEventValueChanged];
    
    self.waveformView = [[WaveformView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, viewhHeight)];
    _waveformView.backgroundColor = [UIColor lightGrayColor];
    _waveformView.waveform = _viewWaveform;
    
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 100)];
    [_infoLabel setTextColor:[UIColor darkGrayColor]];
    _infoLabel.textAlignment = NSTextAlignmentCenter;
    [_infoLabel setFont:[UIFont fontWithName:@"Arial" size:22]];
    
    [self.view addSubview:_waveformView];
    [self.view addSubview:_freezeButton];
    [self.view addSubview:_typeSwitch];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_frozen)
    {
        CGPoint touchLocation = [[touches anyObject] locationInView:self.view];
        _infoLabel.text = [NSString stringWithFormat:@"(%i, %hd)", (int)touchLocation.x,_buffer.samples[(int)touchLocation.x]];
        _infoLabel.center =  CGPointMake(touchLocation.x, touchLocation.y-infoLabelYOffset);
        [self.view addSubview:_infoLabel];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_frozen)
    {
        CGPoint touchLocation = [[touches anyObject] locationInView:self.view];
        _infoLabel.text = [NSString stringWithFormat:@"(%i, %hd)", (int)touchLocation.x ,_buffer.samples[(int)touchLocation.x]];
        _infoLabel.center =  CGPointMake(touchLocation.x, touchLocation.y-infoLabelYOffset);
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_infoLabel removeFromSuperview];
}

-(void)handleFreezeButton:(UIButton*)button
{
    if (!_frozen)
    {
        _frozen = YES;
        [_freezeButton setTitle:@"Draw" forState:UIControlStateNormal];
    }
    else
    {
        _frozen = NO;
        [_freezeButton setTitle:@"Freeze" forState:UIControlStateNormal];
    }
}

-(void)handleTypeSwitch:(UISwitch*)typeSwitch
{
    if (_typeSwitch.on)
    {
        _waveformView.type = WaveformViewTypeLines;
        [_waveformView drawWaveform];
    }
    else
    {
        _waveformView.type = WaveformViewTypeDots;
        [_waveformView drawWaveform];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
