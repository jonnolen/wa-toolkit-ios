//
//  AcsRegisterViewController.h
//  watoolkitios-samples
//
//  Created by Steve Saxon on 7/21/11.
//  Copyright 2011 Neudesic LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AcsRegisterViewController : UIViewController

@property (nonatomic, retain) IBOutlet UITextField *usernameField;
@property (nonatomic, retain) IBOutlet UITextField *emailField;
@property (nonatomic, retain) IBOutlet UIButton *actionButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activity;

- (IBAction)registerClicked:(id)sender;


@end
