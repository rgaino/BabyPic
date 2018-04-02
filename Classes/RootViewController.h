//
//  RootViewController.h
//  Baby Pic
//
//  Created by Rafael Gaino on 11/1/10.
//  Copyright 2010 PunkOpera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "Facebook.h"
#import "UICustomSwitch.h"

@interface RootViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, 
												     AVAudioPlayerDelegate, UITextViewDelegate, FBRequestDelegate> { 
                                                        
	//overlay view outlets
	IBOutlet UIView *overlayView;
	IBOutlet UIButton *flashButton;
	IBOutlet UIButton *shutterButton;
														
	//share screen outlets
	IBOutlet UIImageView *assetImageView;
	IBOutlet UITextView *pictureCaptionTextView;
	IBOutlet UIButton *connectFacebookButton;
	IBOutlet UISwitch *facebookSwitch;
    UICustomSwitch *customSwitch;
	IBOutlet UIButton *saveAndPublishButton;
	IBOutlet UIView *waitIndicatorView;
    IBOutlet UILabel *waitingLabel;
														
	UIImagePickerController *imagePicker;
	NSMutableArray *sounds;
	AVAudioPlayer *audioPlayer;
	BOOL isPlayingSound;
	BOOL isFirstTimeLoadingApp;
	ALAssetsLibrary *library;
	NSDictionary *currentMediaInfo;
                                                         
     int currentSoundButton;
	
	
@private
    NSFetchedResultsController *fetchedResultsController_;
    NSManagedObjectContext *managedObjectContext_;
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, retain) IBOutlet UIView *overlayView;
@property (nonatomic, retain) IBOutlet UIButton *flashButton;
@property (nonatomic, retain) IBOutlet UIButton *shutterButton;
@property (retain, nonatomic) IBOutlet UIButton *galleryButton;
@property (retain, nonatomic) IBOutlet UIImageView *saveMessageImageView;
@property (retain, nonatomic) IBOutlet UIButton *soundButtonFour;
@property (retain, nonatomic) IBOutlet UIButton *soundButtonFive;
@property (retain, nonatomic) IBOutlet UIButton *soundButtonThree;
@property (retain, nonatomic) IBOutlet UIButton *soundButtonTwo;
@property (retain, nonatomic) IBOutlet UIButton *soundButtonOne;
@property (retain, nonatomic) IBOutlet UISlider *volumeSlider;
@property (retain, nonatomic) IBOutlet UIImageView *initialAlertImageView;


@property (nonatomic, retain) IBOutlet UIImageView *assetImageView;
@property (nonatomic, retain) IBOutlet UIView *waitIndicatorView;
@property (nonatomic, retain) IBOutlet UIButton *connectFacebookButton;
@property (nonatomic, retain) IBOutlet UISwitch *facebookSwitch;
@property (nonatomic, retain) IBOutlet UITextView *pictureCaptionTextView;
@property (retain, nonatomic) IBOutlet UIImageView *pictureCaptionImageView;
@property (nonatomic, retain) IBOutlet UIButton *saveAndPublishButton;
@property (nonatomic, retain) IBOutlet UILabel *waitingLabel;
@property (retain, nonatomic) IBOutlet UIButton *cameraSwitchButton;
@property BOOL isFirstTimeLoadingApp;

//actions
-(IBAction) playSound;
-(IBAction) stopSounds;
-(IBAction) shutterPressed;
-(IBAction) flashPressed;
-(IBAction) cameraModePressed;
-(IBAction) doneButtonPressed;
-(IBAction) backButtonPressed;
-(IBAction) connectFacebookPressed;
-(IBAction) facebookSwitchPressed;
- (IBAction)galleryButtonPressed:(id)sender;
- (IBAction)cameraSwitchPressed:(id)sender;

-(void) showCamera;
-(void) fadeOutInitialAlertImageView;
-(void) loadSounds;
-(IBAction) loadSoundOne;
-(IBAction) loadSoundTwo;
-(IBAction) loadSoundThree;
-(IBAction) loadSoundFour;
-(IBAction) loadSoundFive;
-(void) setupOverlayView;
-(void) setupImagePicker;
-(void) showGalleryPicker;
-(void) showAlertForError:(NSError *) error;
-(void) showWaitView;
-(void) hideWaitView;
-(void) showWaitMessage:(NSString *)message;
-(void) setupFacebook;
-(void) saveCurrentMedia;
-(void) publishOnFacebook;
-(void) disconnectFacebook;
-(UIImage*) scaleAndRotateImage:(UIImage*)image;
-(void) animateImageToCameraRoll;
-(void) restoreImageView;

- (void) fbDidLogin;
- (void)request:(FBRequest*)request didFailWithError:(NSError*)error;
- (void)request:(FBRequest*)request didLoad:(id)result;

@end
