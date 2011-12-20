//
//  JSONRequest.h
//
//  Created by stcui on 11-11-9.
//  Copyright (c) 2011年 stcui. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONResponse.h"

@protocol JSONRequestDelegate;

@interface JSONRequest : NSOperation
{
    BOOL _executing;
    BOOL _canceled;
    BOOL _finished;
    NSURLConnection *_connection;

    NSMutableURLRequest *_request;
    NSMutableData *_data;
    NSMutableDictionary *_params;
    NSData *_postData;
    NSString *_paramString;
    JSONResponse *_response;
    NSError *_error;
}
@property (nonatomic, assign) NSObject<JSONRequestDelegate> *delegate;
@property (nonatomic, retain) NSString *HTTPMethod;
@property (nonatomic, retain) NSString *postMethod;
@property (nonatomic, readonly) JSONResponse *response;
@property (nonatomic, readonly) NSError *error;
+ (id)requestWithURL:(NSURL *)URL;
- (id)initWithURL:(NSURL *)URL;
- (id)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval;
- (void)setValue:(NSString *)param forParamKey:(NSString *)key;
- (void)send;
- (NSURL *)url;
- (NSURL *)URL;
@end

@protocol JSONRequestDelegate <NSObject>

- (void)requestFinished:(JSONRequest *)request;
- (void)requestFailed:(JSONRequest *)request;

@end
