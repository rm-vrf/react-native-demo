//
//  BarcodeScanner.swift
//  ReactNativeDemo
//
//  Created by lu on 2022/2/16.
//

import Foundation
import AVFoundation

@objc(BarcodeScannerWrapper)
class BarcodeScannerWrapper: RCTEventEmitter, AVCaptureMetadataOutputObjectsDelegate {
  private var captureSession: AVCaptureSession!
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private var resolve: RCTPromiseResolveBlock!
  private var reject: RCTPromiseRejectBlock!

  override func constantsToExport() -> [AnyHashable: Any]! {
    return ["defaultType": "N/A", "defaultValue": "N/A"]
  }
  
  @objc func requiresMainQueueSetup() -> Bool {
    return false
  }
  
  override func supportedEvents() -> [String]! {
    return ["onScan"]
  }
  
  @objc
  func scanBarcode(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    self.resolve = resolve
    self.reject = reject
    sendEvent(withName: "onScan", body: "create")
    
    captureSession = AVCaptureSession()
    guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
    let videoInput: AVCaptureDeviceInput
    
    do {
      videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
    } catch {
      return
    }
    
    if (captureSession.canAddInput(videoInput)) {
      captureSession.addInput(videoInput)
    } else {
      failed()
      return
    }
    
    let metadataOutput = AVCaptureMetadataOutput()
    
    if (captureSession.canAddOutput(metadataOutput)) {
      captureSession.addOutput(metadataOutput)
      
      metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417]
    } else {
      failed()
      return
    }

    DispatchQueue.main.async {
      let controller = RCTPresentedViewController();
      if let view = controller?.view {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.frame = view.layer.bounds
        self.previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(self.previewLayer)
      }
    }
    sendEvent(withName: "onScan", body: "start")
    captureSession.startRunning()
  }
    
  func failed() {
    sendEvent(withName: "onScan", body: "failed")
    let error = NSError(domain: "react.native.demo", code: 500, userInfo: nil)
    reject("E_BARCODESCAN", "error when scan barcode", error)
  }
    
  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    sendEvent(withName: "onScan", body: "capture")
    captureSession.stopRunning()

    if let metadataObject = metadataObjects.first {
      guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
      guard let stringValue = readableObject.stringValue else { return }
      AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
      previewLayer.removeFromSuperlayer()
      found(code: stringValue)
    }
  }
    
  func found(code: String) {
    print(code)
    resolve(["type": "N/A", "value": "\(code)"])
  }
}
