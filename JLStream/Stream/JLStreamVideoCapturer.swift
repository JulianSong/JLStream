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
    let captureOutput:AVCaptureVideoDataOutput = AVCaptureVideoDataOutput.init()
    var capturePreviewLayer:AVCaptureVideoPreviewLayer?
    let videoCapturerQueue = DispatchQueue.init(label: "JLStream.videoCapturerQueue");
    var connection:AVCaptureConnection?
    
    let encoder = JLStreamDataEncoder.init();
    init(withView view:UIView) {
        super.init()
        if (self.captureSession.canSetSessionPreset(AVCaptureSession.Preset.high)) {
            self.captureSession.sessionPreset = .high
        }
        
        let videoDevice = self.getDevice(type: .video,position: .back)
        let autoDevice = self.getDevice(type: .audio,position:.unspecified)
        if (videoDevice  != nil && autoDevice != nil) {
            do{
                videoDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 30)
                let videoDeviceInput = try AVCaptureDeviceInput.init(device:videoDevice!)
                if (self.captureSession.canAddInput(videoDeviceInput)) {
                    self.captureSession.addInput(videoDeviceInput)
                }
                
                let autoInput  = try AVCaptureDeviceInput.init(device: autoDevice!)
                if (self.captureSession.canAddInput(autoInput)) {
                    self.captureSession.addInput(autoInput)
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
                
            }catch{
                
            }
        }
    }
    
    func getDevice(type:AVMediaType,position:AVCaptureDevice.Position) ->AVCaptureDevice?  {
        if type.rawValue == AVMediaType.video.rawValue {
            let devices = AVCaptureDevice.devices(for:type)
            for device in devices {
                if(device.position.rawValue == position.rawValue){
                    return device
                }
            }
        } else if type.rawValue == AVMediaType.audio.rawValue {
            return AVCaptureDevice.default(for: type)
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
