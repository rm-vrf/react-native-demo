//
//  BarcodeScannerWrapper.m
//  ReactNativeDemo
//
//  Created by lu on 2022/2/16.
//

#import <Foundation/Foundation.h>
#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"

@interface RCT_EXTERN_MODULE(BarcodeScannerWrapper, RCTEventEmitter)

RCT_EXTERN_METHOD(
                  scanBarcode: (RCTPromiseResolveBlock)resolve
                  rejecter: (RCTPromiseRejectBlock)reject
)

@end
