//
//  BarcodeScanButtonManager.m
//  ReactNativeDemo
//
//  Created by htlu on 2022/2/18.
//

#import <Foundation/Foundation.h>
#import "React/RCTViewManager.h"
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(ScanButtonManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(onScanSuccess, RCTDirectEventBlock)

RCT_EXPORT_VIEW_PROPERTY(title, NSString)

RCT_EXPORT_VIEW_PROPERTY(action, NSString)

@end
