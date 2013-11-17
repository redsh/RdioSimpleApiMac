//
//  RdioSimpleApi.m
//  RdioSimpleApi
//
//  Created by Francesco Rossi on 11/16/13.
//  Copyright (c) 2013 Francesco "redsh" Rossi. All rights reserved.
//


#import "RdioSimpleApi.h"
#import "AFOAuth1Client.h"
#import "AFOAuth2Client.h"
#import "AFJSONRequestOperation.h"
#import "JCSSheetController.h"

///// sheet controller for entering rdio conf code

enum {
    kSheetReturnedOk = 1,
    kSheetReturnedCancel = 2
};

@interface RdioCodeSheetController : JCSSheetController

@property (nonatomic, copy) NSString *editString;

- (IBAction)okClicked:(id)sender;
- (IBAction)cancelClicked:(id)sender;

@end

/////

static BOOL secure_store_credentials = FALSE;

@interface RdioSimpleApi ()
{
    AFOAuth1Client* client;
}
@property(nonatomic,copy) RdioAuthBlock urlLoginBlock;

@end

@implementation RdioSimpleApi

#pragma mark Mac OS X

- (void)authenticateInBrowserWithURLScheme:(NSString*)urlScheme block:(RdioAuthBlock)block
{
    [self onlyIfNotLoggedIn:^{
        [self beginAuthentication:^(NSString *authorize_url, NSError *error) {
            
            if(error == nil && authorize_url)
            {
                self.urlLoginBlock = block;
                
                [[NSWorkspace sharedWorkspace] openURLs:@[[NSURL URLWithString:authorize_url]] withAppBundleIdentifier:@"com.apple.Safari" options:nil additionalEventParamDescriptor:nil launchIdentifiers:nil];
                
                
            }
            else
            {
                if(block)block(nil,error);
            }
            
        } withCallbackUrl:[NSString stringWithFormat:@"%@://login",urlScheme]];
        
    }
              loggedInBlock:^{
                  if(block)block(self,nil);
              }
     ];
}

- (void)authenticateInBrowserWithCodeDialog:(NSWindow*)window block:(RdioAuthBlock)block
{
    [self onlyIfNotLoggedIn:^{
        
        [self beginAuthentication:^(NSString *authorize_url, NSError *error) {
            
            if(error == nil && authorize_url)
            {
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:authorize_url]];
            }
            else
            {
                if(block)block(nil, error);
            }
            
            RdioCodeSheetController* sheetController = [[RdioCodeSheetController alloc] init];
            
            [sheetController beginSheetModalForWindow:window completionHandler:^(NSUInteger returnCode) {
                if (returnCode == kSheetReturnedOk)
                {
                    [self completeAuthentication:block withVerifier:sheetController.editString];
                }
                else
                {
                    if(block)block(nil, error);
                }
            }];
            
        } withCallbackUrl:@"oob"];
        
    }
              loggedInBlock:^{
                  if(block)block(self,nil);
              }
     ];
}

#pragma mark user authentication

- (void)beginAuthentication:(RdioAuthBlockInternal)block withCallbackUrl:(NSString*)callback_url
{
    [client setDefaultHeader:@"Accept" value:@""];
    
    [self signedRequest:@"oauth/request_token"
             parameters:@{@"oauth_callback" : callback_url}
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    client.accessToken = [[AFOAuth1Token alloc]initWithQueryString:operation.responseString];
                    
                    NSDictionary* resp = [self parseQSL:operation.responseString];
                    NSString* token       = [resp objectForKey:@"oauth_token"];
                    
                    NSString* url = [NSString stringWithFormat:@"%@?oauth_token=%@",[resp objectForKey:@"login_url"],token];
                    if(block) block(url,nil);
                    
                }
                failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    if(block) block(nil,error);
                }];
    
    
    /*[self call:@"search" parameters:@{
     @"query":@"Get Lucky",
     @"types":@"Track,Album,Artist"
     } block:^(NSDictionary *response, NSError *error) {
     NSLog(@"%@",response);
     }];*/
}

- (void)completeAuthentication:(RdioAuthBlock)block  withVerifier:(NSString*)verifier
{
    [client setDefaultHeader:@"Accept" value:@""];
    
    [self signedRequest:@"oauth/access_token" parameters:@{@"oauth_verifier":verifier} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self setAccessToken:[[AFOAuth1Token alloc] initWithQueryString:operation.responseString]];
        
        if(block) block(self,nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //NSLog(@"completeAuth %@",error);
        if(block) block(nil, error);
    }];
}

- (void)beginAuthentication:(RdioAuthBlockInternal)block
{
    [self beginAuthentication:block withCallbackUrl:@"oob"];
}

#pragma mark login status

-(void)setAccessToken:(AFOAuth1Token*)token
{
    client.accessToken = token;
    
    if(secure_store_credentials)
    {
        [AFOAuth1Token storeCredential:token withIdentifier:@"rdio_token"];
    }
    else
    {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:token];
        [[NSUserDefaults standardUserDefaults]setObject:data forKey:@"rdio_token"];
    }
}

-(void)onlyIfNotLoggedIn:(void(^)())block loggedInBlock:(void(^)())blocklogged
{
    AFOAuth1Token* tok = nil;
    if(secure_store_credentials)
    {
        tok = [AFOAuth1Token retrieveCredentialWithIdentifier:@"rdio_token"];
    }
    else
    {
        NSData* d = [[NSUserDefaults standardUserDefaults]objectForKey:@"rdio_token"];
        tok = [NSKeyedUnarchiver unarchiveObjectWithData:d];
    }
    if(tok)
    {
        client.accessToken = tok;
        
        [self call:@"currentUser"
        parameters:@{}
             block:^(NSDictionary *response, NSError *error) {
                 
                 if(error)
                 {
                     if(block)block();
                 }
                 else
                 {
                     if(blocklogged)blocklogged();
                 }
                 
             }];
        
    }
    else
    {
        if(block) block();
    }
}

- (void)me:(RdioResponseBlock)meBlock
{
    [self call:@"currentUser"
    parameters:@{}
         block:meBlock];
}

- (void)logout
{
    if(secure_store_credentials)
    {
        [AFOAuth1Token deleteCredentialWithIdentifier:@"rdio_token"];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults]setObject:nil forKey:@"rdio_token"];
    }
    client.accessToken = nil;
}

#pragma mark api requests

- (void)call:(NSString*)method parameters:(NSDictionary*)params block:(void(^)(NSDictionary* response, NSError* error))block
{
    [client setDefaultHeader:@"Accept" value:@"application/json"];
    
    NSMutableDictionary* p = [params mutableCopy];
    [p setObject:method forKey:@"method"];
    
    [self signedRequest:@"1/" parameters:p
                success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    
                    if(block) block(responseObject, nil);
                    
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    
                    /*
                     if(error is .. token expiration logout and login)
                     {
                     [self logout];
                     }
                     */
                    if(block) block(nil, error);
                    
                }];
}


#pragma generic utilities

- (void)signedRequest:(NSString *)path
           parameters:(NSDictionary *)parameters
              success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    
    [client postPath:path parameters:parameters
             success:^(AFHTTPRequestOperation *operation, id responseObject){
                 if([operation isKindOfClass:[AFJSONRequestOperation class]])
                 {
                     AFJSONRequestOperation* op = (AFJSONRequestOperation*) operation;
                     success(op,op.responseJSON);
                 }
                 else
                 {
                     success(operation,responseObject);
                 }
                 
             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 failure(operation,error);
             }];
}

-(NSDictionary*)parseQSL:(NSString*)str
{
    NSMutableDictionary* resp = [[NSMutableDictionary alloc]init];
    NSArray* comps = [str componentsSeparatedByString:@"&"];
    
    for(NSString* c in comps)
    {
        NSArray* kv = [c componentsSeparatedByString:@"="];
        NSString* val = [kv objectAtIndex:1];
        
        [resp setObject:[val stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding] forKey:[kv objectAtIndex:0]];
    }
    return resp;
}

- (id)init
{
    self = [super init];
    
    if(!self) return nil;
    
    return self;
}

- (void)setupWithKey:(NSString*)RDIO_key andSecret:(NSString*)RDIO_secret
{
    client = [[AFOAuth1Client alloc]initWithBaseURL:[NSURL URLWithString:@"http://api.rdio.com/"] key:RDIO_key secret:RDIO_secret];
    
    [client registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    //Mac OS Safari redirect handle
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
}

//Mac OS Safari redirect handle
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString* s = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSDictionary* resp = [self parseQSL:[[s componentsSeparatedByString:@"?"]objectAtIndex:1]];
    
    //NSLog(@"%@ %@",resp, [resp objectForKey:@"oauth_verifier"]);
    [self completeAuthentication:self.urlLoginBlock withVerifier:[resp objectForKey:@"oauth_verifier"]];
    
    self.urlLoginBlock = nil;
}

-(void)dealloc
{
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager removeEventHandlerForEventClass:kInternetEventClass andEventID:kAEGetURL];
}

+(RdioSimpleApi*)shared
{
    static RdioSimpleApi* ret = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ret = [[RdioSimpleApi alloc]init];
    });
    return ret;
}

@end


///// sheet controller for entering rdio conf code

@implementation RdioCodeSheetController
@synthesize editString;

- (id)init {
    if (!(self = [super initWithWindowNibName:@"RdioCodeSheet"])) {
        return nil; // Bail!
    }
    return self;
}
- (IBAction)onEnter:(id)sender {
    [self endSheetWithReturnCode:kSheetReturnedOk];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void)okClicked:(id)sender {
    [self endSheetWithReturnCode:kSheetReturnedOk];
}

- (void)cancelClicked:(id)sender {
    [self endSheetWithReturnCode:kSheetReturnedCancel];
}

- (void)sheetWillDisplay {
    [super sheetWillDisplay];
}

@end

//////
