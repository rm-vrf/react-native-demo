//
//  BarcodeScanButton.swift
//  ReactNativeDemo
//
//  Created by lu on 2022/2/18.
//

import UIKit
import BarcodeScanner

class ScanButton : UIView {
  
  @objc var onScanSuccess: RCTDirectEventBlock?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.addSubview(button)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @objc
  var title: String = "" {
    didSet {
      button.setTitle(title, for: .normal)
    }
  }
  
  @objc
  var action: String = "" {
    didSet {
      if action == "scan" {
        didScan()
      }
    }
  }
  
  lazy var button: UIButton = {
    let b = UIButton.init(type: UIButton.ButtonType.system)
    b.setTitle("Scan", for: .normal)
    b.backgroundColor = .white
    b.setTitleColor(.black, for: .normal)
    b.frame = CGRect(x: 100, y: 100, width: 200, height: 52)
    b.addTarget(self, action: #selector(didScan), for: .touchUpInside)
    return b
  }()
  
  @objc func didScan() {
    print("didScan")
    let viewController = BarcodeScannerViewController()
    viewController.codeDelegate = self
    viewController.errorDelegate = self
    viewController.dismissalDelegate = self
    
    let controller = RCTPresentedViewController();
    controller?.present(viewController, animated: true, completion: nil)
  }
}

extension ScanButton : BarcodeScannerCodeDelegate {
  func scanner(_ controller: BarcodeScannerViewController, didCaptureCode code: String, type: String) {
    print("type: \(type), code: \(code)")
    controller.dismiss(animated: true, completion: nil)
    if onScanSuccess != nil {
      onScanSuccess!(["type": type, "code": code])
    }
  }
}

extension ScanButton : BarcodeScannerErrorDelegate {
  func scanner(_ controller: BarcodeScannerViewController, didReceiveError error: Error) {
    print("\(error)")
  }
}

extension ScanButton : BarcodeScannerDismissalDelegate {
  func scannerDidDismiss(_ controller: BarcodeScannerViewController) {
    controller.dismiss(animated: true, completion: nil)
  }
}
