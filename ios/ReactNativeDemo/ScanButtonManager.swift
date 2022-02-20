//
//  BarcodeScanButtonManager.swift
//  ReactNativeDemo
//
//  Created by lu on 2022/2/18.
//

import Foundation

@objc(ScanButtonManager)
class ScanButtonManager : RCTViewManager {
  
  override func view() -> UIView! {
    return ScanButton()
  }
  
  override static func requiresMainQueueSetup() -> Bool {
    return false
  }
}
