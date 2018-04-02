//
//  RootViewController.m
//  Baby Pic
//
//  Created by Rafael Gaino on 11/1/10.
//  Copyright 2010 PunkOpera. All rights reserved.
//

#import "RootViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "Pet_PicAppDelegate.h"
#import "FBConnect.h"
#import <MediaPlayer/MPVolumeView.h>
#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Alpha.h"

#define kSoundIndexDefault @"SoundIndexKey"

@implementation RootViewController
@synthesize soundButtonFive;
@synthesize soundButtonThree;
@synthesize soundButtonTwo;
@synthesize soundButtonOne;
@synthesize volumeSlider;
@synthesize initialAlertImageView;
@synthesize pictureCaptionImageView;
@synthesize galleryButton;
@synthesize saveMessageImageView;
@synthesize soundButtonFour;

@synthesize fetchedResultsController=fetchedResultsController_, managedObjectContext=managedObjectContext_;
@synthesize overlayView, flashButton, shutterButton, assetImageView, waitIndicatorView;
@synthesize connectFacebookButton, facebookSwitch, pictureCaptionTextView, saveAndPublishButton, waitingLabel;
@synthesize cameraSwitchButton;
@synthesize isFirstTimeLoadingApp;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setTitle:@"Baby Pic"];
	[self.navigationController setNavigationBarHidden:YES];

	library = [[ALAssetsLibrary alloc] init];

	[self loadSounds];
	[self setupOverlayView];
	[self setupImagePicker];
    
    customSwitch = [UICustomSwitch switchWithLeftText:@"ON" andRight:@"OFF" andFrame:CGRectMake(245,268,0,0)];
    [self.view addSubview:customSwitch];
    [customSwitch addTarget:self action:@selector(facebookSwitchPressed) forControlEvents:UIControlEventTouchUpInside];

}


-(void)viewWillAppear:(BOOL)animated {

	[self setupFacebook];
	
	if(isFirstTimeLoadingApp) {
		isFirstTimeLoadingApp = NO;
		[self showCamera];
	}
}

#pragma mark IBActions

-(IBAction) doneButtonPressed {

	[self performSelector:@selector(showWaitView) withObject:nil];
	
	if( [customSwitch isOn]) {
		[self publishOnFacebook];		
	} else {		
		[self saveCurrentMedia];
	}

}		


-(IBAction) backButtonPressed {
	
	[currentMediaInfo release];
	[self showCamera];
}



-(IBAction) playSound {
	
	if(isPlayingSound) {
		
		NSError *err;
		int soundIndex = arc4random() % [sounds count];

        NSLog(@"Will play file %@",[sounds objectAtIndex:soundIndex]);
		audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[sounds objectAtIndex:soundIndex] error:&err];
		if( err ){
			NSLog(@"Failed with reason: %@", [err localizedDescription]);
		} else {
			audioPlayer.delegate = self;
			[audioPlayer play];
		}
	}
	
}


-(IBAction) stopSounds {
	isPlayingSound = NO;
    [audioPlayer stop];
	[soundButtonOne setImage:[UIImage imageNamed:@"sound_button_1_off"] forState:UIControlStateNormal];
	[soundButtonTwo setImage:[UIImage imageNamed:@"sound_button_2_off"] forState:UIControlStateNormal];
	[soundButtonThree setImage:[UIImage imageNamed:@"sound_button_3_off"] forState:UIControlStateNormal];
	[soundButtonFour setImage:[UIImage imageNamed:@"sound_button_4_off"] forState:UIControlStateNormal];
	[soundButtonFive setImage:[UIImage imageNamed:@"sound_button_5_off"] forState:UIControlStateNormal];
}


-(void) showCamera {
	
	isPlayingSound = YES;
	[pictureCaptionTextView setText:@""];
    
    [self.initialAlertImageView setAlpha:1.0f];
	[self presentModalViewController:imagePicker animated:YES];
	
//	[self performSelector:@selector(playSound) withObject:nil afterDelay:2.0f];

    [self performSelector:@selector(restoreImageView) withObject:nil afterDelay:1.0f];

    [self performSelector:@selector(fadeOutInitialAlertImageView) withObject:nil afterDelay:5.0f];
}

-(void) fadeOutInitialAlertImageView {
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];
    
    [initialAlertImageView setAlpha:0.0f];
    
    [UIView commitAnimations];  
}

-(void) restoreImageView {
    [assetImageView setTransform:CGAffineTransformMakeScale(1.0, 1.0)];
    [assetImageView setFrame:CGRectMake(80, 82, 150, 150)];
    [assetImageView setAlpha:1.0f];
}

-(IBAction) flashPressed {
	
	if( [imagePicker cameraFlashMode] == UIImagePickerControllerCameraFlashModeOff ) {
		[flashButton setImage:[UIImage imageNamed:@"flash_auto"] forState:UIControlStateNormal];
		[imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeAuto];
	}
	else if( [imagePicker cameraFlashMode] == UIImagePickerControllerCameraFlashModeAuto ) {
		[flashButton setImage:[UIImage imageNamed:@"flash_on"] forState:UIControlStateNormal];
		[imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOn];
	}
	else if( [imagePicker cameraFlashMode] == UIImagePickerControllerCameraFlashModeOn ) {
		[flashButton setImage:[UIImage imageNamed:@"flash_off"] forState:UIControlStateNormal];
		[imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
	}
}


-(IBAction) cameraModePressed {
	
	if( [imagePicker cameraCaptureMode] == UIImagePickerControllerCameraCaptureModeVideo ) {
		
		[imagePicker setCameraCaptureMode:UIImagePickerControllerCameraCaptureModePhoto];
		
	} else {
		
		[imagePicker setCameraCaptureMode:UIImagePickerControllerCameraCaptureModeVideo];
	}
}


-(IBAction) shutterPressed {
	
	[self stopSounds];
	
	[imagePicker takePicture];
}

- (IBAction)galleryButtonPressed:(id)sender {
    [self showGalleryPicker];
}

- (IBAction)cameraSwitchPressed:(id)sender {
    
    [UIView beginAnimations:nil context:NULL];

    if(imagePicker.cameraDevice == UIImagePickerControllerCameraDeviceFront)
    {
        [imagePicker setCameraDevice:UIImagePickerControllerCameraDeviceRear];  
    } else
    {
        [imagePicker setCameraDevice:UIImagePickerControllerCameraDeviceFront];          
    }
    
    [UIView commitAnimations];
}




#pragma mark Setup Views


-(void) setupOverlayView {
	
	[overlayView setBackgroundColor:[UIColor clearColor]];
	[overlayView setFrame:CGRectMake(0, 0, 320, 460)];
	
	[flashButton setHidden:![UIImagePickerController isFlashAvailableForCameraDevice:UIImagePickerControllerCameraDeviceRear]];
		
	[cameraSwitchButton setHidden: ![UIImagePickerController isCameraDeviceAvailable: UIImagePickerControllerCameraDeviceFront]];

    
    
    

    
    
    MPVolumeView *volumeView = [[[MPVolumeView alloc] initWithFrame: CGRectMake(38, 50, 244, 15)] autorelease];
    NSArray *tempArray = volumeView.subviews;
    
    for (id current in tempArray){
        if ([current isKindOfClass:[UISlider class]]){
            UISlider *tempSlider = (UISlider *) current;
            
            UIImage *minImage = [UIImage imageNamed:@"vol_green_track.png"];
            UIImage *maxImage = [UIImage imageNamed:@"vol_white_track.png"];
            UIImage *tumbImage= [UIImage imageNamed:@"vol_circle.png"];
            
            minImage=[minImage stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
            maxImage=[maxImage stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
            
            [tempSlider setMinimumTrackImage:minImage forState:UIControlStateNormal];
            
            [tempSlider setMaximumTrackImage:maxImage forState:UIControlStateNormal];
            
            [tempSlider setThumbImage:tumbImage forState:UIControlStateNormal];
            tempSlider.minimumValue = 0.0;
            tempSlider.maximumValue = 1.0;
            tempSlider.continuous = YES;
        } 
    }
    [volumeSlider removeFromSuperview];
    [self.overlayView addSubview:volumeView];
}


-(void) setupImagePicker {
		
	imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.sourceType =  UIImagePickerControllerSourceTypeCamera;
	imagePicker.delegate = self;
	[imagePicker setAllowsEditing:NO];
	[imagePicker setShowsCameraControls:NO];
	[imagePicker setCameraOverlayView:overlayView];
	[imagePicker setCameraCaptureMode:UIImagePickerControllerCameraCaptureModePhoto];
	[imagePicker setMediaTypes:[UIImagePickerController availableMediaTypesForSourceType:[imagePicker sourceType]]];	
	[imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
}

-(void) showGalleryPicker {
    
	UIImagePickerController *galleryPicker = [[UIImagePickerController alloc] init];
	galleryPicker.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
	galleryPicker.delegate = self;
	[galleryPicker setAllowsEditing:NO];
    [galleryPicker setMediaTypes:[NSArray arrayWithObject:(NSString *) kUTTypeImage]];

    [self presentModalViewController:galleryPicker animated:YES];
}

#pragma mark Sounds

-(void) loadSounds {
	
	sounds = [[NSMutableArray alloc] init];

}


-(IBAction) loadSoundOne {
	
    if (currentSoundButton==1) {
        [self stopSounds];
        return;
    }
    currentSoundButton=1;
    isPlayingSound = YES;

	[soundButtonOne setImage:[UIImage imageNamed:@"sound_button_1_on"] forState:UIControlStateNormal];
	[soundButtonTwo setImage:[UIImage imageNamed:@"sound_button_2_off"] forState:UIControlStateNormal];
	[soundButtonThree setImage:[UIImage imageNamed:@"sound_button_3_off"] forState:UIControlStateNormal];
	[soundButtonFour setImage:[UIImage imageNamed:@"sound_button_4_off"] forState:UIControlStateNormal];
	[soundButtonFive setImage:[UIImage imageNamed:@"sound_button_5_off"] forState:UIControlStateNormal];
	
	[sounds release];
	
	NSString *bundleResourcePath = [[NSBundle mainBundle] resourcePath];
	NSURL *soundFileURL; 
	sounds = [[NSMutableArray alloc] init];
	
	soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/bell_seq1.mp3"]];
	[sounds addObject:soundFileURL];
	
	soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/vai_vem_1.mp3"]];
	[sounds addObject:soundFileURL];
	
	soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/xilofone_1.mp3"]];
	[sounds addObject:soundFileURL];
	
	soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/xilofone_2.mp3"]];
	[sounds addObject:soundFileURL];

    [audioPlayer stop];
    [self playSound];
}

-(IBAction) loadSoundTwo {
	
    if (currentSoundButton==2) {
        [self stopSounds];
        return;
    }
    currentSoundButton=2;
	isPlayingSound = YES;

	[soundButtonOne setImage:[UIImage imageNamed:@"sound_button_1_off"] forState:UIControlStateNormal];
	[soundButtonTwo setImage:[UIImage imageNamed:@"sound_button_2_on"] forState:UIControlStateNormal];
	[soundButtonThree setImage:[UIImage imageNamed:@"sound_button_3_off"] forState:UIControlStateNormal];
	[soundButtonFour setImage:[UIImage imageNamed:@"sound_button_4_off"] forState:UIControlStateNormal];
	[soundButtonFive setImage:[UIImage imageNamed:@"sound_button_5_off"] forState:UIControlStateNormal];
	
	[sounds release];
	
	NSString *bundleResourcePath = [[NSBundle mainBundle] resourcePath];
	NSURL *soundFileURL; 
	sounds = [[NSMutableArray alloc] init];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/annoying pig.mp3"]];
	[sounds addObject:soundFileURL];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/frog.mp3"]];
	[sounds addObject:soundFileURL];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/squeeze-toy-1.mp3"]];
	[sounds addObject:soundFileURL];

    [audioPlayer stop];
    [self playSound];
}

-(IBAction) loadSoundThree {
    
    if (currentSoundButton==3) {
        [self stopSounds];
        return;
    }
    currentSoundButton=3;
	isPlayingSound = YES;

	[soundButtonOne setImage:[UIImage imageNamed:@"sound_button_1_off"] forState:UIControlStateNormal];
	[soundButtonTwo setImage:[UIImage imageNamed:@"sound_button_2_off"] forState:UIControlStateNormal];
	[soundButtonThree setImage:[UIImage imageNamed:@"sound_button_3_on"] forState:UIControlStateNormal];
	[soundButtonFour setImage:[UIImage imageNamed:@"sound_button_4_off"] forState:UIControlStateNormal];
	[soundButtonFive setImage:[UIImage imageNamed:@"sound_button_5_off"] forState:UIControlStateNormal];
	
	[sounds release];
	
	NSString *bundleResourcePath = [[NSBundle mainBundle] resourcePath];
	NSURL *soundFileURL; 
	sounds = [[NSMutableArray alloc] init];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/buzina.mp3"]];
	[sounds addObject:soundFileURL];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/buzina2.mp3"]];
	[sounds addObject:soundFileURL];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/Buzina_0.mp3"]];
	[sounds addObject:soundFileURL];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/buzina_3.mp3"]];
	[sounds addObject:soundFileURL];

    [audioPlayer stop];
    [self playSound];
}


-(IBAction) loadSoundFour {
    
    if (currentSoundButton==4) {
        [self stopSounds];
        return;
    }
    currentSoundButton=4;
	isPlayingSound = YES;

    [soundButtonOne setImage:[UIImage imageNamed:@"sound_button_1_off"] forState:UIControlStateNormal];
	[soundButtonTwo setImage:[UIImage imageNamed:@"sound_button_2_off"] forState:UIControlStateNormal];
	[soundButtonThree setImage:[UIImage imageNamed:@"sound_button_3_off"] forState:UIControlStateNormal];
	[soundButtonFour setImage:[UIImage imageNamed:@"sound_button_4_on"] forState:UIControlStateNormal];
	[soundButtonFive setImage:[UIImage imageNamed:@"sound_button_5_off"] forState:UIControlStateNormal];
	
	[sounds release];
	
	NSString *bundleResourcePath = [[NSBundle mainBundle] resourcePath];
	NSURL *soundFileURL; 
	sounds = [[NSMutableArray alloc] init];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/mix_1.mp3"]];
	[sounds addObject:soundFileURL];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/music_1.mp3"]];
	[sounds addObject:soundFileURL];

    [audioPlayer stop];
    [self playSound];
}

-(IBAction) loadSoundFive {
    
    if (currentSoundButton==5) {
        [self stopSounds];
        return;
    }
    currentSoundButton=5;
	isPlayingSound = YES;

    [soundButtonOne setImage:[UIImage imageNamed:@"sound_button_1_off"] forState:UIControlStateNormal];
	[soundButtonTwo setImage:[UIImage imageNamed:@"sound_button_2_off"] forState:UIControlStateNormal];
	[soundButtonThree setImage:[UIImage imageNamed:@"sound_button_3_off"] forState:UIControlStateNormal];
	[soundButtonFour setImage:[UIImage imageNamed:@"sound_button_4_off"] forState:UIControlStateNormal];
	[soundButtonFive setImage:[UIImage imageNamed:@"sound_button_5_on"] forState:UIControlStateNormal];
	
	[sounds release];
	
	NSString *bundleResourcePath = [[NSBundle mainBundle] resourcePath];
	NSURL *soundFileURL; 
	sounds = [[NSMutableArray alloc] init];
	
    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/chocalho_2.mp3"]];
	[sounds addObject:soundFileURL];

    soundFileURL = [NSURL fileURLWithPath:[bundleResourcePath stringByAppendingString:@"/risadas.mp3"]];
	[sounds addObject:soundFileURL];
    
    [audioPlayer stop];
    [self playSound];
}



- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	
	[self dismissModalViewControllerAnimated:YES];

	UIImage *picture = [info objectForKey:UIImagePickerControllerOriginalImage];
	[assetImageView setImage:[picture thumbnailImage:150 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationHigh]];

	currentMediaInfo = info;
	[currentMediaInfo retain];

	
	return;
}

-(void) saveCurrentMedia {
	
	[self performSelectorInBackground:@selector(showWaitMessage:) withObject:@"Saving..."];
		
	UIImage *picture = [currentMediaInfo objectForKey:UIImagePickerControllerOriginalImage];
	NSDictionary *metadata = [currentMediaInfo objectForKey:UIImagePickerControllerMediaMetadata];
	
	[library writeImageToSavedPhotosAlbum:[picture CGImage] metadata:metadata 
									  completionBlock:
										^(NSURL *assetURL, NSError *error){
											if (error != NULL) {
												[self showAlertForError:error];
												return;
											}
										}
	];

	[self hideWaitView];
    [self animateImageToCameraRoll];
    [self performSelector:@selector(showCamera) withObject:nil afterDelay:1.2f];
}


-(void) animateImageToCameraRoll {
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:1.0];

    NSLog(@"%.1f, %.1f, %.1f, %.1f", assetImageView.frame.origin.x, assetImageView.frame.origin.y, assetImageView.frame.size.width, assetImageView.frame.size.height);
    [assetImageView setFrame:CGRectMake(0, 400, 58, 58)];
    [assetImageView setAlpha:0.0f];
    [assetImageView setTransform:CGAffineTransformMakeScale(0.2, 0.2)];

    [UIView commitAnimations];
}



-(void) showAlertForError:(NSError*) error {
	
	[self hideWaitView];

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Error"
						  message: [error localizedDescription]
						  delegate: nil
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil];
	
	[alert show];
	[alert release];
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {

	[audioPlayer release];	
	[self playSound];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[pictureCaptionTextView resignFirstResponder];
}


-(BOOL)textViewShouldBeginEditing:(UITextView *)textField {
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:0.25];
	
	CGAffineTransform transform;
	
	transform = CGAffineTransformMakeTranslation(0, -120);
	self.view.transform = transform;
	
	[UIView commitAnimations];
	
	return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:0.25];
	
	CGAffineTransform transform;
	
	transform = CGAffineTransformMakeTranslation(0, 0);
	self.view.transform = transform;
	
	[UIView commitAnimations];
	
	return YES;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	
	if ([text hasSuffix:@"\n"]) {
		[self textViewShouldEndEditing:textView];
		[textView resignFirstResponder];
		return NO;
	}
	
	return YES;
}


-(void) showWaitView {
	[waitIndicatorView setHidden:NO];
}

-(void) hideWaitView {
	[waitIndicatorView setHidden:YES];
}

-(void) showWaitMessage:(NSString *)message {
	[waitingLabel setText:message];
}



#pragma mark Facebook
-(void) setupFacebook {
	
	Pet_PicAppDelegate* appDelegate = (Pet_PicAppDelegate*)[[UIApplication sharedApplication] delegate];
    Facebook *facebook = [appDelegate facebook];

//    if(facebook == nil) {
//        facebook = [[Facebook alloc] initWithAppId:kFacebookAppId andDelegate:self];
//    }
    
//	facebook.accessToken    = [[NSUserDefaults standardUserDefaults] stringForKey:@"AccessToken"];
//    facebook.expirationDate = (NSDate *) [[NSUserDefaults standardUserDefaults] objectForKey:@"ExpirationDate"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"] && [defaults objectForKey:@"FBExpirationDateKey"]) {
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
	
    
    
    if ([facebook isSessionValid]) {
		[customSwitch setOn:YES];
		[connectFacebookButton setHidden:YES];
		[customSwitch setHidden:NO];
        [saveMessageImageView setImage:[UIImage imageNamed:@"then_save_and_publish.png"]];
        [pictureCaptionImageView setHidden:NO];
        [pictureCaptionTextView setHidden:NO];
    } else {
        [customSwitch setOn:NO];
		[connectFacebookButton setHidden:NO];
		[customSwitch setHidden:YES];
        [saveMessageImageView setImage:[UIImage imageNamed:@"or_save_it.png"]];
        [pictureCaptionImageView setHidden:YES];
        [pictureCaptionTextView setHidden:YES];
	}

	[self facebookSwitchPressed];
	
}

-(IBAction) facebookSwitchPressed {

	if([customSwitch isOn]) {	
		[saveAndPublishButton setImage:[UIImage imageNamed:@"button_publish"] forState:UIControlStateNormal];
        [saveMessageImageView setImage:[UIImage imageNamed:@"then_save_and_publish.png"]];
        [pictureCaptionImageView setHidden:NO];
        [pictureCaptionTextView setHidden:NO];
	} else {
		[saveAndPublishButton setImage:[UIImage imageNamed:@"button_save"] forState:UIControlStateNormal];
        [saveMessageImageView setImage:[UIImage imageNamed:@"or_save_it.png"]];
        [pictureCaptionImageView setHidden:YES];
        [pictureCaptionTextView setHidden:YES];
	}
}



-(IBAction) connectFacebookPressed {

	Pet_PicAppDelegate* appDelegate = (Pet_PicAppDelegate*)[[UIApplication sharedApplication] delegate];
	Facebook *facebook = [appDelegate facebook];

	NSArray *permissions =  [NSArray arrayWithObjects:@"publish_stream", @"offline_access",nil];
//	[facebook authorize:kFacebookAppId permissions:permissions delegate:self];
	[facebook authorize:permissions];
}


- (void) fbDidLogin
{
	Pet_PicAppDelegate* appDelegate = (Pet_PicAppDelegate*)[[UIApplication sharedApplication] delegate];
	Facebook *facebook = [appDelegate facebook];

//    [[NSUserDefaults standardUserDefaults] setObject:facebook.accessToken forKey:@"AccessToken"];
//    [[NSUserDefaults standardUserDefaults] setObject:facebook.expirationDate forKey:@"ExpirationDate"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
	
	[self setupFacebook];
}


- (void)request:(FBRequest*)request didFailWithError:(NSError*)error {
	
	if([error code] == 190 || [error code] == 101) {
		//permission error
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Facebook"
														message: @"You must connect with Facebook again"
													   delegate: nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		
		[alert show];
		[alert release];
		
		[self disconnectFacebook];
		[self setupFacebook];
	}
	else {
		[self showAlertForError:error];		
	}

	[self hideWaitView];
}


- (void)request:(FBRequest*)request didLoad:(id)result {

	[self saveCurrentMedia];
}


-(void) disconnectFacebook {
	
	Pet_PicAppDelegate* appDelegate = (Pet_PicAppDelegate*)[[UIApplication sharedApplication] delegate];
	Facebook *facebook = [appDelegate facebook];
	
	[facebook logout];
	[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"AccessToken"];
	[[NSUserDefaults standardUserDefaults] setObject:[[NSDate date] addTimeInterval: -86400.0] forKey:@"ExpirationDate"];

}


-(void) publishOnFacebook {
	
	[self performSelectorInBackground:@selector(showWaitMessage:) withObject:@"Publishing..."];
	
	Pet_PicAppDelegate* appDelegate = (Pet_PicAppDelegate*)[[UIApplication sharedApplication] delegate];
	Facebook *facebook = [appDelegate facebook];
	
	UIImage *sourceImage = [currentMediaInfo objectForKey:UIImagePickerControllerOriginalImage];
	UIImage *img = [self scaleAndRotateImage:sourceImage];
	
	NSMutableDictionary * params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									img, @"picture",
									[pictureCaptionTextView text], @"caption",
									nil];
	
	@try {
		[facebook requestWithMethodName: @"photos.upload"
							  andParams: params
						  andHttpMethod: @"POST"
							andDelegate: self];
		
	}
	@catch (NSException * e) {
		NSLog(@"Exception is %@", [e reason]);
	}
	
}


#pragma mark UIImage method

-(UIImage*) scaleAndRotateImage:(UIImage*)image {
	
    int kMaxResolution = 700; // Or whatever
	
    CGImageRef imgRef = image.CGImage;
	
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
	
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
	
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
			
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
			
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
			
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
			
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
			
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
			
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
			
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
			
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
			
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
			
    }
	
    UIGraphicsBeginImageContext(bounds.size);
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
	
    CGContextConcatCTM(context, transform);
	
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return imageCopy;
}


#pragma mark Memory management
- (void)dealloc {
        
	[sounds release];
	[overlayView release];
	[flashButton release];
	[shutterButton release];
	[library release];
	[assetImageView release];
	[waitIndicatorView release];
	[connectFacebookButton release];
	[facebookSwitch release];
	[pictureCaptionTextView release];
	[saveAndPublishButton release];
	[waitingLabel release];
	
	[fetchedResultsController_ release];
    [managedObjectContext_ release];
	
    [galleryButton release];
    [saveMessageImageView release];
    [pictureCaptionImageView release];
    [soundButtonFive release];
    [soundButtonFour release];
    [soundButtonThree release];
    [soundButtonTwo release];
    [soundButtonOne release];
    [volumeSlider release];
    [cameraSwitchButton release];
    [initialAlertImageView release];
    [super dealloc];
}


- (void)viewDidUnload {
    [self setGalleryButton:nil];
    [self setSaveMessageImageView:nil];
    [self setPictureCaptionImageView:nil];
    [self setSoundButtonFive:nil];
    [self setSoundButtonFour:nil];
    [self setSoundButtonThree:nil];
    [self setSoundButtonTwo:nil];
    [self setSoundButtonOne:nil];
    [self setVolumeSlider:nil];
    [self setCameraSwitchButton:nil];
    [self setInitialAlertImageView:nil];
    [super viewDidUnload];
}
@end

