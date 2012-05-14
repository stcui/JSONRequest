//
//  JSONRequest.m
//
//  Created by stcui on 11-11-9.
//  Copyright (c) 2011年 stcui. All rights reserved.
//

#import "JSONRequest.h"

static NSString *userAgent = nil;
static NSOperationQueue *s_requestQueue = nil;;

@interface JSONRequest ()
- (void)finish;
- (void)setResponse:(JSONResponse *)response;
@end

@implementation JSONRequest
@synthesize delegate = _delegate;
@synthesize HTTPMethod = _HTTPMethod;
@synthesize postMethod = _postMethod;
@synthesize response = _response;
@synthesize error = _error;

- (id)retain {
    return [super retain];
}


+ (void)initialize
{
    if ([self class] == [JSONRequest class]) {
        NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleIdentifier"];
        UIDevice *currentDevice = [UIDevice currentDevice];
        userAgent = [[NSString alloc] initWithFormat:@"%@(%@/%@)", bundleId, [currentDevice systemName],
                     [currentDevice systemVersion]];
        s_requestQueue = [[NSOperationQueue alloc] init];
        [s_requestQueue setMaxConcurrentOperationCount:4];
    }
}

+ (id)requestWithURL:(NSURL *)URL
{
    id request = [[[self alloc] initWithURL:URL] autorelease];
    return request;
}

+ (void)setMaxConcurrentRequestCount:(NSInteger)count
{
    @synchronized(s_requestQueue) {
        [s_requestQueue setMaxConcurrentOperationCount:count];
    }
}

- (id)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval
{
    self = [super init];
    if (self) {
        NSURL *url = URL;
        if ([URL isKindOfClass:[NSString class]]) {
            url = [NSURL URLWithString:(NSString*)URL];
        }
        _request = [[NSMutableURLRequest alloc] initWithURL:url
                                                cachePolicy:cachePolicy
                                            timeoutInterval:timeoutInterval];
        _params = [[NSMutableDictionary alloc] initWithCapacity:0];
        [_request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [_request setValue:@"gzip,deflate,sdch" forHTTPHeaderField:@"Accept-Encoding"];
        [_request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
        self.HTTPMethod = @"GET";
    }

    return self;
}

- (id)initWithURL:(NSURL *)URL
{
    self = [self initWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:100];
    return self;
}

- (void)dealloc
{
    [_HTTPMethod release];
    [_request release];
    [_error release];
    [_postData release];
    [_params release];
    [_paramString release];
    [_data release];
    [_response release];
    [_sentDate release];
    [super dealloc];
}

- (NSData *)toData:(id)object
{
    if ([object isKindOfClass:[NSString class]]) {
        return [object dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([object isKindOfClass:[NSNumber class]]) {
        return [[object stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([object isKindOfClass:[UIImage class]]) {
        return UIImagePNGRepresentation(object);
    } else if ([object isKindOfClass:[NSData class]]) {
        return object;
    }
    return nil;
}

- (void)buildMultipartFormDataPostBody
{
    NSMutableData *result = [[NSMutableData alloc] initWithCapacity:512];
    
	CFUUIDRef uuid = CFUUIDCreate(nil);
	NSString *uuidString = [(NSString*)CFUUIDCreateString(nil, uuid) autorelease];
	CFRelease(uuid);
	NSString *stringBoundary = [NSString stringWithFormat:@"0xKhTmLbOuNdArY-%@",uuidString];
	
    [_request setValue:[NSString stringWithFormat:@"multipart/form-data; charset=%@; boundary=%@", @"UTF-8", stringBoundary] forHTTPHeaderField:@"Content-Type"];
	
	[result appendData:[self toData:[NSString stringWithFormat:@"--%@\r\n",stringBoundary]]];
	// Adds post data
	NSString *endItemBoundary = [NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary];
	NSUInteger i=0;
    NSEnumerator *keyEnumerator = [_params keyEnumerator];
    NSInteger count = [_params count];
	for (NSString *key in keyEnumerator) {
        id value = [_params objectForKey:key];
        NSString *filename = nil;
        if ([value isKindOfClass:[UIImage class]]) {
            filename = @"file";
        } else if ([value isKindOfClass:[NSData class]]) {
            filename = @"file";
        }
        if (filename) {
            [result appendData:[self toData:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, filename]]];
            [result appendData:[self toData:[NSString stringWithFormat:@"Content-Type: image/png\r\n\r\n"]]];
        } else {
            [result appendData:[self toData:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key]]];
        }
        [result appendData:[self toData:value]];
		++i;
		if (i < count) { //Only add the boundary if this is not the last item in the post body
			[result appendData:[self toData: endItemBoundary]];
		}
	}
	
	[result appendData:[self toData:[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary]]];
    
    [_postData release];
    _postData = result;
}

- (void)buildParamString
{
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:512];
    NSInteger count = [_params count];
    NSInteger i = 0;
    NSEnumerator *keyEnumerator = [_params keyEnumerator];
    for (NSString *key in keyEnumerator) {
        [result appendFormat:@"%@=%@", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
         [[_params valueForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        if (i++ < count) {
            [result appendFormat:@"&"];
        }
    }
    [_paramString release];
    _paramString = result;
}

- (void)buildURLEncodingParams
{
    [self buildParamString];
    
    [_postData release];
    _postData = [[NSData alloc] initWithBytes:[_paramString cStringUsingEncoding:NSUTF8StringEncoding]
                                       length:[_paramString length]];
}

- (void)buildPostBody
{
    if ([self.postMethod isEqualToString:@"multipart"]) {
        [self buildMultipartFormDataPostBody];
    } else {
        [self buildParamString];
    }
}

- (BOOL)isPostMethod
{
    return [self.HTTPMethod isEqualToString:@"POST"] || [self.HTTPMethod isEqualToString:@"PUT"];
}

- (void)setValue:(NSString *)param forParamKey:(NSString *)key
{
    [_params setValue:param forKey:key];
}

- (void)buildURL
{
    [self buildParamString];
    NSURL *url = [_request URL];
    NSString *paramString = [url parameterString];
    if (_paramString && [_paramString length]) {
        NSMutableString *newURL = [[NSMutableString alloc] initWithCapacity:128];
        [newURL appendFormat:@"%@", url];
        if (paramString && [paramString length] > 0) {
            [newURL appendString:@"&"];
        } else if (![[[url description] substringWithRange:NSMakeRange([url description].length - 1, 1)] isEqualToString:@"?"])
        {
            [newURL appendString:@"?"];
        }
        [newURL appendString:_paramString];
        [_request setURL:[NSURL URLWithString:newURL]];
        [newURL release];
    }
}

- (NSDate *)sentDate
{
    return _sentDate;
}
#pragma mark - NSOperation
- (void)start
{
    if ([self isFinished]) {
        return;
    }
    if ([self isCancelled]) {
        NSLog(@"canceled before start");
        [self finish];
        return;
    }
   
    [self willChangeValueForKey:@"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

    _connection = [[NSURLConnection alloc] initWithRequest:_request
                                                  delegate:self
                                          startImmediately:NO];
    if (_connection) {
        _data = [[NSMutableData alloc] initWithCapacity:128];
        [_connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [_connection start];
    } else {
        [self finish];
    }
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isCancelled
{
    return _canceled;
}

- (BOOL)isFinished
{
    return _finished;
}

- (void)cancel
{
    if ([self isFinished]||[self isCancelled]) {
        return;
    }
    [self willChangeValueForKey:@"isCancelled"];
    _canceled = YES;
    [_connection cancel];
    [self didChangeValueForKey:@"isCancelled"];
    [self finish];
}


- (void)finish
{
    if ([self isFinished]) {
        return;
    }
    if ( ! [self isExecuting]) {
        return;
    }
    NSLog(@"%s current thread: %@", __PRETTY_FUNCTION__, [NSThread currentThread]);
    [_connection release]; //_connection = nil;
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    _finished = YES;
    _executing = NO;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
    [self release];
    
    NSLog(@"end of %s", __PRETTY_FUNCTION__);
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    NSLog(@"connection will send");
    return request;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"connection failed");
    _error = [error retain];
    [self.delegate performSelectorOnMainThread:@selector(requestFailed:) withObject:self waitUntilDone:YES];
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"%s did received", __PRETTY_FUNCTION__);
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (! [self isCancelled]) {
        @autoreleasepool {
            [self setResponse:[JSONResponse responseWithData:_data]];
            [self.delegate performSelectorOnMainThread:@selector(requestFinished:) withObject:self waitUntilDone:YES];
        }
        [self finish];
    }
}

- (void)setResponse:(JSONResponse *)response
{
    if (_response == response) {
        return;
    }
    [_response release];
    _response = [response retain];
}
#pragma mark 
- (void)addToMainQueue
{
    [s_requestQueue addOperation:self];    
}

- (void)send
{
    _sentDate = [[NSDate alloc] init];
    [self retain];
    _request.HTTPMethod = self.HTTPMethod;
    if ([self isPostMethod]) {
        [self buildPostBody];
        _request.HTTPBody = _postData;
    } else {
        [self buildURL];
    }
    [self addToMainQueue];
}

- (NSURL *)URL
{
    return [_request URL];
}

- (NSURL *)url
{
    return  [self URL];
}

@end
