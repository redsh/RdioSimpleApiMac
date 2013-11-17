//
//  RdioSimpleApi.h
//  RdioSimpleApi
//
//  Created by Francesco Rossi on 11/16/13.
//  Copyright (c) 2013 Francesco "redsh" Rossi. All rights reserved.
//


@class RdioSimpleApi;

typedef void(^RdioAuthBlock)(RdioSimpleApi* api, NSError* error);
typedef void(^RdioAuthBlockInternal)(NSString* authorize_url, NSError* error);
typedef void(^RdioResponseBlock)(NSDictionary* resp, NSError* err);

@interface RdioSimpleApi : NSObject

+(RdioSimpleApi*)shared;
- (void)setupWithKey:(NSString*)key andSecret:(NSString*)secret;

- (void)authenticateInBrowserWithURLScheme:(NSString*)urlScheme block:(RdioAuthBlock)block;
- (void)authenticateInBrowserWithCodeDialog:(NSWindow*)window block:(RdioAuthBlock)block;

- (void)logout;


- (void)me:(RdioResponseBlock)dict;

- (void)call:(NSString*)method parameters:(NSDictionary*)params block:(void(^)(NSDictionary* response, NSError* error))block;

//

- (void)beginAuthentication:(RdioAuthBlockInternal)block;

- (void)beginAuthentication:(RdioAuthBlockInternal)block withCallbackUrl:(NSString*)callback_url;

@end



