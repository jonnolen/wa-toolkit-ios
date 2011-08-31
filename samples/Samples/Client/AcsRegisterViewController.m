//
//  AcsRegisterViewController.m
//  watoolkitios-samples
//
//  Created by Steve Saxon on 7/21/11.
//  Copyright 2011 Neudesic LLC. All rights reserved.
//

#import "AcsRegisterViewController.h"
#import "WACloudAccessControlClient.h"
#import "WACloudAccessToken.h"
#import "WAConfiguration.h"
#import "ServiceCall.h"
#import "Azure_Storage_ClientAppDelegate.h"

@implementation AcsRegisterViewController

@synthesize usernameField;
@synthesize actionButton;
@synthesize activity;
@synthesize emailField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
	{
        // Custom initialization
		self.title = @"Registration";
    }
    return self;
}

- (void)dealloc
{
    [usernameField release];
	[emailField release];
	[activity release];
	[actionButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view from its nib.	
	[usernameField becomeFirstResponder];
	
	WACloudAccessToken* sharedToken = [WACloudAccessControlClient sharedToken];
	NSDictionary* claims = sharedToken.claims;
	
	if(claims)
	{
		self.usernameField.text = [claims objectForKey:@"name"];
		self.emailField.text = [claims objectForKey:@"emailaddress"];
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)registerClicked:(id)sender 
{
	[usernameField resignFirstResponder];
	[emailField resignFirstResponder];
	
	if(!usernameField.text.length || !emailField.text.length)
	{
		UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"Registration" 
													   message:@"All fields must be filled in."
													  delegate:self 
											 cancelButtonTitle:@"OK" 
											 otherButtonTitles:nil];
		[view show];
		[view release];
		return;
	}
	
	[activity startAnimating];
	actionButton.enabled = NO;
	
	NSString* payload = [ServiceCall xmlBuilder:@"RegistrationUser" 
								objectNamespace:@"Microsoft.Samples.WindowsPhoneCloud.StorageClient.Credentials", 
						 @"EMail", emailField.text,
						 @"Name", usernameField.text,
						 nil];

	WAConfiguration* config = [WAConfiguration sharedConfiguration];	
	NSString* url = @"/RegistrationService/register";
	
	[ServiceCall postXmlToURL:[config proxyURL:url] body:payload withDictionaryCompletionHandler:^(NSDictionary *values, NSError *error) 
	 {
		 [activity stopAnimating];
		 actionButton.enabled = YES;
		 
		 if(error)
		 {
			 UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"Registration" 
															message:[NSString stringWithFormat:@"An error occurred (%@)", [error localizedDescription]]
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			 [view show];
			 [view release];
			 return;
		 }
		 
		 NSString* str = [values objectForKey:@"text"];
		 
		 if([str isEqualToString:@"Success"])
		 {
			 [Azure_Storage_ClientAppDelegate bindAccessToken];
			 [self.navigationController popToRootViewControllerAnimated:YES];
		 }
		 else if([str isEqualToString:@"DuplicateUserName"])
		 {
			 UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"Registration" 
															message:@"Username is already registered."
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			 [view show];
			 [view release];
		 }
		 else if([str isEqualToString:@"DuplicateEmail"])
		 {
			 UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"Registration" 
															message:@"Email is already registered."
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			 [view show];
			 [view release];
		 }
		 else
		 {
			 UIAlertView* view = [[UIAlertView alloc] initWithTitle:@"Registration" 
															message:@"User could not be registered."
														   delegate:self 
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil];
			 [view show];
			 [view release];
		 }
	 }];
}

- (void)loginDidSucceed
{
	actionButton.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[activity stopAnimating];
	
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)loginDidFailWithError:(NSError *)error
{
	actionButton.enabled = YES;
	[activity stopAnimating];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login Error" message:[NSString stringWithFormat:@"An error occurred: %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


@end
