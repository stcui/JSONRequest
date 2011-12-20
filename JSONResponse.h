//
//  JSONResponse.h
//
//  Created by stcui on 11-11-9.
//  Copyright (c) 2011年 stcui. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSONResponse : NSObject
{
@protected
    NSError *_error;
    NSDictionary *_rootObject;
}
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) NSDictionary *rootObject;
+ (id)responseWithData:(NSData *)data;
- (id)initWithData:(NSData *)data;
@end
