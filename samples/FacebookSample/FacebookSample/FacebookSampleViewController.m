//
//  FacebookSampleViewController.m
//  FacebookSample
//
//  Created by Scott Densmore on 11/27/11.
//  Copyright 2011 Scott Densmore. All rights reserved.
//

#import "FacebookSampleViewController.h"

@implementation FacebookSampleViewController

@synthesize loginButton;
@synthesize friendsButton;
@synthesize friendLabel;

- (void)dealloc 
{
    _token = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.friendsButton = nil;
    self.loginButton = nil;
    self.friendLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)login:(id)sender 
{
    self.loginButton.hidden = YES;
    WACloudAccessControlClient *acsClient = [WACloudAccessControlClient accessControlClientForNamespace:@"scottdeniosacs2" realm:@"uri:wazmobiletoolkit"];
    [acsClient showInViewController:self allowsClose:NO withCompletionHandler:^(BOOL authenticated) { 
        if (!authenticated) { 
            NSLog(@"Error authenticating"); 
            self.loginButton.hidden = NO;
        } else { 
            _token = [WACloudAccessControlClient sharedToken]; 
            self.friendsButton.hidden = NO;
        }
    }];
}

- (IBAction)friends:(id)sender 
{
    NSMutableArray *httpEncoding = [NSMutableArray arrayWithObjects:[NSArray arrayWithObjects:@"%3a",@":",nil], 
                                    [NSArray arrayWithObjects:@"%2f",@"/",nil], 
                                    nil]; 
    
    NSString *localSecuirtyToken = [_token securityToken];
    while ([httpEncoding count] >= 1) { 
        localSecuirtyToken = [localSecuirtyToken stringByReplacingOccurrencesOfString:[[httpEncoding objectAtIndex:0] objectAtIndex:0] 
                                                                   withString:[[httpEncoding objectAtIndex:0] objectAtIndex:1]]; 
        [httpEncoding removeObjectAtIndex:0]; 
    }
    
    NSError *error = NULL;
    NSString *fbuserId = [[_token claims] objectForKey:@"nameidentifier"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"http://www.facebook.com/claims/AccessToken=([A-Za-z0-9]*)" 
                                                      options:0 
                                                        error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:localSecuirtyToken 
                                                    options:0 
                                                      range:NSMakeRange(0, [localSecuirtyToken length])];
    NSRange firstRange = [match rangeAtIndex:1];
    NSString *oauthToken = [localSecuirtyToken substringWithRange:firstRange];
    
    // Get my friends
    NSString *graphURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/friends?access_token=%@",fbuserId,oauthToken];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:graphURL]];
    NSURLResponse *response = NULL;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *friendsList = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    regex = [NSRegularExpression regularExpressionWithPattern:@"id" options:0 error:&error];
    NSUInteger friendCount = [regex numberOfMatchesInString:friendsList options:0 range:NSMakeRange(0, [friendsList length])];
    [friendsList release];
    
    self.friendLabel.text = [NSString stringWithFormat:@"%d friends", friendCount];
    self.friendLabel.hidden = NO;
}
@end
