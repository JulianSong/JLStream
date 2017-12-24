//
//  JLStreamRTMPEngine.swift
//  JLStream
//
//  Created by Julian.Song on 2017/12/16.
//  Copyright © 2017年 Junliang Song. All rights reserved.
//http://www.qingpingshan.com/rjbc/ios/339004.html

import UIKit
import VideoToolbox


class JLStreamRTMPEngine: NSObject {
    let sendQueue = DispatchQueue.init(label: "JLStream.RTMPQueue");
    var rtmp:UnsafeMutablePointer<RTMP>!
    func crete() {
        self.sendQueue.sync {
            self.rtmp = RTMP_Alloc()
            RTMP_Init(self.rtmp)
            RTMP_LogSetLevel(RTMP_LOGALL)
            let url:String = "rtmp://192.168.31.209:1935/rtmplive/room"
            if RTMP_SetupURL(self.rtmp,UnsafeMutablePointer<Int8>(mutating: url.cString(using: .utf8))) == 0{
                print("rtmp 无法设置url");
            }
            RTMP_EnableWrite(self.rtmp)
            if RTMP_Connect(self.rtmp,nil) == 0{
                print("rtmp 无法链接");
            }
            
            if RTMP_ConnectStream(self.rtmp,0) == 0{
                print("rtmp strem 无法链接");
            }
        }
    }
    
    fileprivate var NALUHeader: [UInt8] = [0, 0, 0, 1]
    func send(spsData:NSData,ppsData:NSData) {
        self.sendQueue.sync {
            let spsFullData: NSMutableData = NSMutableData(bytes: NALUHeader, length: NALUHeader.count)
            spsFullData.append(spsData.bytes, length: spsData.length)
            RTMP_Write(self.rtmp,UnsafePointer<Int8>(OpaquePointer(spsFullData.bytes)),Int32(spsFullData.length))
            let ppsFullData: NSMutableData = NSMutableData(bytes: NALUHeader, length: NALUHeader.count)
            ppsFullData.append(ppsData.bytes, length: ppsData.length)
            RTMP_Write(self.rtmp,UnsafePointer<Int8>(OpaquePointer(ppsFullData.bytes)),Int32(ppsFullData.length))
//            var packet:UnsafeMutablePointer<RTMPPacket>!
//            RTMPPacket_Alloc(packet, 1024*64)
//            RTMPPacket_Reset(packet);
//            packet.pointee.m_hasAbsTimestamp = 0
//            packet.pointee.m_nChannel = 0x04
//            packet.pointee.m_nInfoField2 = self.rtmp.pointee.m_stream_id
//            RTMP_SendPacket(self.rtmp, packet, 0)
            
            
        }
    }
    
    func send(_ data:NSData, isKeyFrame:Bool){
        self.sendQueue.sync {
            let headerData: NSMutableData = NSMutableData(bytes: NALUHeader, length: NALUHeader.count)
            headerData.append(data.bytes, length: data.length)
            RTMP_Write(self.rtmp,UnsafePointer<Int8>(OpaquePointer(headerData.bytes)),Int32(headerData.length))
//            if  RTMP_Write(self.rtmp,UnsafePointer<Int8>(OpaquePointer(data.bytes)),Int32(data.length)) == 0 {
//                print("rtmp RTMP_Write");
//            }
        }
    }
}
