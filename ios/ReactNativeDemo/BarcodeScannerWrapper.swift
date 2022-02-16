//
//  BarcodeScanner.swift
//  ReactNativeDemo
//
//  Created by lu on 2022/2/16.
//

import Foundation
import AVFoundation

@objc(BarcodeScannerWrapper)
class BarcodeScannerWrapper: NSObject, AVCaptureMetadataOutputObjectsDelegate {
  private var captureSession: AVCaptureSession!
  private var previewLayer: AVCaptureVideoPreviewLayer!
  private var resolve: RCTPromiseResolveBlock!
  private var reject: RCTPromiseRejectBlock!

  @objc
  func constantsToExport() -> [AnyHashable: Any]! {
    return ["defaultType": "N/A", "defaultValue": "N/A"]
  }
  
  @objc
  func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  @objc
  func scanBarcode(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    self.resolve = resolve
    self.reject = reject
    
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
    
//    let controller = RCTPresentedViewController();
//    if let view = controller?.view {
//      previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//      previewLayer.frame = view.layer.bounds
//      previewLayer.videoGravity = .resizeAspectFill
//      view.layer.addSublayer(previewLayer)
//    }
    captureSession.startRunning()
  }
    
  func failed() {
    let error = NSError(domain: "react.native.demo", code: 500, userInfo: nil)
    reject("E_BARCODESCAN", "error when scan barcode", error)
  }
    
  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    captureSession.stopRunning()

    if let metadataObject = metadataObjects.first {
      guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
      guard let stringValue = readableObject.stringValue else { return }
      AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
      //previewLayer.dismiss()
      found(code: stringValue)
    }
  }
    
  func found(code: String) {
    print(code)
    resolve(["type": "EAN-13", "value": "\(code)"])
  }
}
