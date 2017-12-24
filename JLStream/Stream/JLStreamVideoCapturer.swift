//
//  JLStreamVideoCapturer.swift
//  JLStream
//
//  Created by Julian.Song on 2017/12/16.
//  Copyright © 2017年 Junliang Song. All rights reserved.
//

import UIKit
import AVFoundation

class JLStreamVideoCapturer: NSObject,AVCaptureVideoDataOutputSampleBufferDelegate{
    let captureSession:AVCaptureSession = AVCaptureSession.init()
    var captureDeviceInput:AVCaptureDeviceInput?
    let captureOutput:AVCaptureVideoDataOutput = AVCaptureVideoDataOutput.init()
    var capturePreviewLayer:AVCaptureVideoPreviewLayer?
    let videoCapturerQueue = DispatchQueue.init(label: "JLStream.videoCapturerQueue");
    var connection:AVCaptureConnection?
    var captureDevice:AVCaptureDevice?
    let encoder = JLStreamDataEncoder.init();
    init(withView view:UIView) {
        super.init()
        if (self.captureSession.canSetSessionPreset(AVCaptureSession.Preset.high)) {
            self.captureSession.sessionPreset = .high
        }
        self.captureDevice = self.getDevice(position: .back)
        if (self.captureDevice  != nil) {
            self.captureDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 30)
            try! self.captureDeviceInput = AVCaptureDeviceInput.init(device: self.captureDevice!)
            if (self.captureSession.canAddInput(self.captureDeviceInput!)) {
                self.captureSession.addInput(self.captureDeviceInput!)
            }
            
            if (self.captureSession.canAddOutput(self.captureOutput)) {
                self.captureOutput.alwaysDiscardsLateVideoFrames = true
                self.captureOutput.setSampleBufferDelegate(self, queue: self.videoCapturerQueue)
                self.captureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                
                self.captureSession.addOutput(self.captureOutput)
                self.captureSession.beginConfiguration()
                self.connection = self.captureOutput.connection(with: .video)
                self.connection?.videoOrientation = .portrait
                self.captureSession.commitConfiguration()
            }
            self.capturePreviewLayer = AVCaptureVideoPreviewLayer.init(session: self.captureSession);
            self.capturePreviewLayer?.videoGravity = .resizeAspectFill;
            self.capturePreviewLayer?.frame = view.frame;
            view.layer.addSublayer(self.capturePreviewLayer!);
            self.encoder.createVTSession()
        }
    }
    
    func getDevice(position:AVCaptureDevice.Position) ->AVCaptureDevice?  {
        let camares = AVCaptureDevice.devices(for:.video)
        for camare in camares {
            if(camare.position.rawValue == position.rawValue){
                return camare
            }
        }
        return nil
    }
    func start() {
        self.captureSession.startRunning()
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
     func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print(sampleBuffer)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print(sampleBuffer)
        self.encoder.encode(sampleBuffer)
    }
}
