//
//  BarcodeScanner.swift
//  ReactNativeDemo
//
//  Created by htlu on 2022/2/16.
//

import Foundation

@objc(BarcodeScannerWrapper)
class BarcodeScannerWrapper: NSObject {

  @objc
  func constantsToExport() -> [AnyHashable: Any]! {
    return ["defaultType": "N/A", "defaultValue": "N/A"]
  }
  
  @objc
  func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  private var count:Int = 0
  
  @objc
  func scanBarcode(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    count += 1
    if count % 2 == 0 {
      resolve(["type": "\(count)", "value": "\(count)"])
    } else {
      let error = NSError(domain: "react.native.demo", code: 500, userInfo: nil)
      reject("E_BARCODESCAN", "error when scan barcode", error)
    }
  }
}
