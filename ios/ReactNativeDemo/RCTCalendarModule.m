//
//  RCTCalendarModule.m
//  ReactNativeDemo
//
//  Created by lu on 2022/2/16.
//

#import <Foundation/Foundation.h>
#import <React/RCTLog.h>
#import "RCTCalendarModule.h"

@implementation RCTCalendarModule

// To export a module named RCTCalendarModule
RCT_EXPORT_MODULE(RCTCalendarModule);

RCT_EXPORT_METHOD(createCalendarEvent:(NSString *)title
                  location:(NSString *)location
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  RCTLogInfo(@"Pretending to create an event %@ at %@", title, location);
  NSTimeInterval ts = [[NSDate date] timeIntervalSince1970];
  NSNumber *eventId = [NSNumber numberWithDouble:ts];
  if (eventId) {
    resolve(eventId);
  } else {
    reject(@"event_failure", @"no event id returned", nil);
  }
}

@end
