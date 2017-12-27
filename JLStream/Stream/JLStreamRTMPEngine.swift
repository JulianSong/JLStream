//
//  JLStreamRTMPEngine.swift
//  JLStream
//
//  Created by Julian.Song on 2017/12/16.
//  Copyright © 2017年 Junliang Song. All rights reserved.
//http://www.qingpingshan.com/rjbc/ios/339004.html
//http://www.voidcn.com/article/p-dbegjdij-ov.html

import UIKit
import VideoToolbox


class JLStreamRTMPEngine: NSObject {
    let sendQueue = DispatchQueue.init(label: "JLStream.RTMPQueue");
    var rtmp:UnsafeMutablePointer<RTMP>!
    func crete() {
        self.sendQueue.sync {
            self.setupRTMP()
        }
    }
    
    func setupRTMP(){
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
        if RTMP_ConnectStream(self.rtmp,10) == 0{
            print("rtmp strem 无法链接");
        }
    }
    
    fileprivate var NALUHeader: [UInt8] = [0, 0, 0, 1]
    func send(spsData:NSData,ppsData:NSData) {
        self.sendQueue.sync {
            let fullData: NSMutableData = NSMutableData(bytes: NALUHeader, length: NALUHeader.count)
            fullData.append(spsData.bytes, length: spsData.length)
            fullData.append(NALUHeader, length: NALUHeader.count)
            fullData.append(ppsData.bytes, length: ppsData.length)
            self.send(data: fullData.copy() as! NSData, timeStamp: 0)
        }
    }
    
    func send(_ data:NSData, isKeyFrame:Bool, timeStamp:UInt32){
        self.sendQueue.sync {
            let fullData: NSMutableData = NSMutableData(bytes: NALUHeader, length: NALUHeader.count)
            fullData.append(data.bytes, length: data.length)
            self.send(data: fullData.copy() as! NSData, timeStamp: timeStamp)
        }
    }
    
    func send(data:NSData,timeStamp:UInt32){
        let mbody = UnsafeMutableRawPointer.allocate(bytes: data.length, alignedTo: MemoryLayout<Int8>.alignment)
        mbody.copyBytes(from: data.bytes, count: data.length)
        if RTMP_IsConnected(self.rtmp) == 1{
            let packetRaw:RTMPPacket =  RTMPPacket.init(m_headerType:  UInt8(RTMP_PACKET_SIZE_LARGE),
                                                        m_packetType: UInt8(RTMP_PACKET_TYPE_VIDEO),
                                                        m_hasAbsTimestamp: 0,
                                                        m_nChannel: 0x04,
                                                        m_nTimeStamp:timeStamp,
                                                        m_nInfoField2: self.rtmp.pointee.m_stream_id,
                                                        m_nBodySize: UInt32(data.length),
                                                        m_nBytesRead: 0,
                                                        m_chunk: nil,
                                                        m_body:mbody.assumingMemoryBound(to: Int8.self)
            )
            let packet = UnsafeMutablePointer<RTMPPacket>.allocate(capacity: 1)
            packet.initialize(to: packetRaw)
            if RTMP_SendPacket(self.rtmp,packet, 0) == 0{
                print("send idr error \(packet)")
            }
            packet.deinitialize(count: 1)
            packet.deallocate(capacity: 1)
            mbody.deallocate(bytes: data.length, alignedTo: MemoryLayout<Int8>.alignment)
        }else {
            
        }
    }
}
