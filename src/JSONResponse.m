//
//  JSONResponse.m
//
//  Created by stcui on 11-11-9.
//  Copyright (c) 2011年 stcui. All rights reserved.
//

#import "JSONResponse.h"
#import "JSONKit.h"

@implementation JSONResponse
@synthesize error = _error;
@synthesize rootObject = _rootObject;

+ (id)responseWithData:(NSData *)data
{
    JSONResponse *response = [[[JSONResponse alloc] initWithData:data] autorelease];
    return response;
}

- (id)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        _rootObject = [[data objectFromJSONDataWithParseOptions:JKParseOptionLooseUnicode
                                                          error:&_error] retain];
        [_error retain];
    }
    
    return self;
}

- (void)dealloc {
    [_rootObject release];
    [_error release];
    [super dealloc];
}

@end
