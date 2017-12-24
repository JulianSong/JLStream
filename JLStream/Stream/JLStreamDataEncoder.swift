//
//  JLStreamDataEncoder.swift
//  JLStream
//
//  Created by Julian.Song on 2017/12/16.
//  Copyright © 2017年 Junliang Song. All rights reserved.
//http://liuley.cn/%E6%8A%80%E6%9C%AF/2016/03/15/iOS-rtmp-live-stream
//https://www.zybuluo.com/qvbicfhdx/note/126161
//http://www.jianshu.com/p/a3beefbb7d1d
//https://mobisoftinfotech.com/resources/mguide/h264-encode-decode-using-videotoolbox/
//https://tomisacat.xyz/tech/2017/08/21/iOS-hardware-accelerate-codec-with-videotoolbox.html
//http://jailbreaklife.com/blog/2016/08/15/mac-nginx-rtmp/

import UIKit
import VideoToolbox
import AVFoundation


func compressionOutputCallback(outputCallbackRefCon: UnsafeMutableRawPointer?,
                               sourceFrameRefCon: UnsafeMutableRawPointer?,
                               status: OSStatus,
                               infoFlags: VTEncodeInfoFlags,
                               sampleBuffer: CMSampleBuffer?) -> Swift.Void {
    
    guard status == noErr else {
        print("error: \(status)")
        return
    }
    
    if infoFlags == .frameDropped {
        print("frame dropped")
        return
    }
    
    guard let sampleBuffer = sampleBuffer else {
        print("sampleBuffer is nil")
        return
    }
    
    if CMSampleBufferDataIsReady(sampleBuffer) != true {
        print("sampleBuffer data is not ready")
        return
    }
    
    let encoder:JLStreamDataEncoder = Unmanaged.fromOpaque(outputCallbackRefCon!).takeUnretainedValue()
    
    let attachmentsArray:CFArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, false)!
    var isKeyFrame = false
    if  CFArrayGetCount(attachmentsArray) > 0{
        let rawDic: UnsafeRawPointer = CFArrayGetValueAtIndex(attachmentsArray, 0)
        let dict: CFDictionary = Unmanaged.fromOpaque(rawDic).takeUnretainedValue()
        isKeyFrame = CFDictionaryContainsKey(dict,Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque())
    }
    
    if isKeyFrame {
        let format = CMSampleBufferGetFormatDescription(sampleBuffer)
        var spsSize: Int = 0
        var spsCount: Int = 0
        var nalHeaderLength: Int32 = 0
        var sps: UnsafePointer<UInt8>?
        if CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format!,0,&sps,&spsSize,&spsCount,&nalHeaderLength) == noErr {
            // pps
            var ppsSize: Int = 0
            var ppsCount: Int = 0
            var pps: UnsafePointer<UInt8>?
            
            if CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format!,1,&pps,&ppsSize,&ppsCount,&nalHeaderLength) == noErr {
                let spsData: NSData = NSData(bytes: sps, length: spsSize)
                let ppsData: NSData = NSData(bytes: pps, length: ppsSize)
                encoder.rtmp.send(spsData:spsData,ppsData:ppsData)
            }
        }
    }
    
    guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
        return
    }
    
    var lengthAtOffset: Int = 0
    var totalLength: Int = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    let presentationTimestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
    
    let timeStamp:Int64 =  Int64(presentationTimestamp.value) / Int64(presentationTimestamp.timescale)
    print("timeStamp is \(timeStamp)")
    if CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &dataPointer) == noErr {
        var bufferOffset: Int = 0
        let AVCCHeaderLength = 4
        while bufferOffset < (totalLength - AVCCHeaderLength) {
            var NALUnitLength: UInt32 = 0
            // first four character is NALUnit length
            memcpy(&NALUnitLength, dataPointer?.advanced(by: bufferOffset), AVCCHeaderLength)
            // big endian to host endian. in iOS it's little endian
            NALUnitLength = CFSwapInt32BigToHost(NALUnitLength)
            let data: NSData = NSData(bytes: dataPointer?.advanced(by: bufferOffset + AVCCHeaderLength), length: Int(NALUnitLength))
            encoder.rtmp.send(data,isKeyFrame:isKeyFrame,timeStamp:UInt32(timeStamp))
            // move forward to the next NAL Unit
            bufferOffset += Int(AVCCHeaderLength)
            bufferOffset += Int(NALUnitLength)
        }
    }
}

class JLStreamDataEncoder: NSObject{
    var session:VTCompressionSession?
    let encodeQueue = DispatchQueue.init(label: "JLStream.encodeQueue")
    let rtmp = JLStreamRTMPEngine.init()
    func createVTSession()  {
        let width = 320
        let height = 200
        let status:OSStatus = VTCompressionSessionCreate(kCFAllocatorDefault,Int32(width),Int32(height), kCMVideoCodecType_H264,nil, nil, nil,compressionOutputCallback,Unmanaged.passUnretained(self).toOpaque(), &self.session)
        if status == noErr {
            VTSessionSetProperty(self.session!, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel)
            // capture from camera, so it's real time
            VTSessionSetProperty(self.session!, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue)
            // 关键帧间隔
            VTSessionSetProperty(self.session!, kVTCompressionPropertyKey_MaxKeyFrameInterval, 10 as CFTypeRef)
            // 比特率和速率
            VTSessionSetProperty(self.session!, kVTCompressionPropertyKey_AverageBitRate, width * height * 2 * 32 as CFTypeRef)
            VTSessionSetProperty(self.session!, kVTCompressionPropertyKey_DataRateLimits, [width * height * 2 * 4, 1] as CFArray)
            VTCompressionSessionPrepareToEncodeFrames(self.session!)
            self.rtmp.crete()
        }else{
            
        }
        
    }
    
    func encode(_ sampleBuffer:CMSampleBuffer){
        self.encodeQueue.sync {
            var encodeInfoFlags:VTEncodeInfoFlags = .asynchronous
            let imgaeBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//            let presentationTimestamp = CMTime.init(value: 20, timescale: 30)
            let presentationTimestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            let duration = CMSampleBufferGetOutputDuration(sampleBuffer)
            VTCompressionSessionEncodeFrame(self.session!,imgaeBuffer,presentationTimestamp,duration,nil,nil,&encodeInfoFlags)
            
        }
    }
}
