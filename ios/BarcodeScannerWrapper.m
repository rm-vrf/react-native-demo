//
//  BarcodeScannerWrapper.m
//  ReactNativeDemo
//
//  Created by htlu on 2022/2/16.
//

#import <Foundation/Foundation.h>
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(BarcodeScannerWrapper, NSObject)

RCT_EXTERN_METHOD(
                  scanBarcode: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject
)

@end
