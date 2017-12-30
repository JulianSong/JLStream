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

public protocol JLStreamRTMPEngineDelegate:NSObjectProtocol {
    func RTMPEngine( _ RTMPEngine:JLStreamRTMPEngine, didConnect success: Bool,error:String?)
}

public class JLStreamRTMPEngine: NSObject {
    let sendQueue = DispatchQueue.init(label: "JLStream.RTMPQueue");
    var rtmp:UnsafeMutablePointer<RTMP>!
    var datas = Array<JLStreamRTMPData>()
    var semaphore = DispatchSemaphore.init(value: 1)
    var url:String?
    var pushing = false
    weak var delegate:JLStreamRTMPEngineDelegate?
    fileprivate var NALUHeader: [UInt8] = [0, 0, 0, 1]
}

extension JLStreamRTMPEngine {
    func crete( _ url:String) {
        self.url = url
        self.sendQueue.async{
            self.setupRTMP()
        }
    }
    
    func setupRTMP(){
        self.rtmp = RTMP_Alloc()
        RTMP_Init(self.rtmp)
        if self.rtmp == nil {
            print("create rtmp fail");
            self.delegate?.RTMPEngine(self, didConnect: false, error:"create rtmp fail")
            return
        }
        
        //        RTMP_LogSetLevel(RTMP_LOGALL)
        
        if RTMP_SetupURL(self.rtmp,UnsafeMutablePointer<Int8>(mutating: self.url?.cString(using: .utf8))) == 0 {
            print("rtmp setup url fail");
            self.delegate?.RTMPEngine(self, didConnect: false, error:"rtmp setup url fail")
        }
        
        RTMP_EnableWrite(self.rtmp)
        if RTMP_Connect(self.rtmp,nil) == 0 {
            print("rtmp connect fail");
            self.delegate?.RTMPEngine(self, didConnect: false, error:"rtmp setup url fail")
        }
        
        if RTMP_ConnectStream(self.rtmp,0) == 0 {
            print("rtmp connect stream fail");
            self.delegate?.RTMPEngine(self, didConnect: false, error:"rtmp connect stream fail")
        }else{
            print("rtmp connect stream sec");
            self.delegate?.RTMPEngine(self, didConnect: true, error:nil)
        }
    }
}

extension JLStreamRTMPEngine {
    func send(spsData:NSData,ppsData:NSData) {
        let fullData: NSMutableData = NSMutableData(bytes: NALUHeader, length: NALUHeader.count)
        fullData.append(spsData.bytes, length: spsData.length)
        fullData.append(NALUHeader, length: NALUHeader.count)
        fullData.append(ppsData.bytes, length: ppsData.length)
        self.addData(data: fullData,timeStamp: 0)
    }
    
    func send(_ data:NSData, isKeyFrame:Bool, timeStamp:UInt32){
        let fullData: NSMutableData = NSMutableData(bytes: NALUHeader, length: NALUHeader.count)
        fullData.append(data.bytes, length: data.length)
        self.addData(data: fullData,timeStamp: timeStamp)
    }
    
    private func addData(data:NSData,timeStamp: UInt32){
        if !self.pushing {
            return
        }
        self.semaphore.wait()
        self.datas.append(JLStreamRTMPData(NAULData: data, timeStamp: timeStamp))
        self.semaphore.signal()
    }

}

extension JLStreamRTMPEngine {
    
    func startPush() ->Bool {
        if self.pushing || self.rtmp == nil || RTMP_IsConnected(self.rtmp) == 0{
            return false;
        }
        
        self.pushing = true
        self.sendQueue.async{
            while self.pushing {
                if self.datas.count > 0{
                    for i in 0..<self.datas.count {
                        let data = self.datas[i]
                        self.push(data)
                    }
                    self.semaphore.wait()
                    self.datas.removeAll()
                    self.semaphore.signal()
                }
            }
        }
        return true
    }
    
    func stopPush() {
        self.pushing = false
    }
    
    private func push(_ data:JLStreamRTMPData){
        
        if self.rtmp == nil{
//            self.setupRTMP()
            return
        }
        
        guard let rawData = data.NAULData else {
            return
        }
          
        let length = rawData.length
        if RTMP_IsConnected(self.rtmp) == 1{
            let mbody = UnsafeMutableRawPointer.allocate(bytes: length, alignedTo: MemoryLayout<Int8>.alignment)
            mbody.copyBytes(from: rawData.bytes, count:length)
            let packetRaw:RTMPPacket =  RTMPPacket.init(m_headerType:  UInt8(RTMP_PACKET_SIZE_MEDIUM),
                                                        m_packetType: UInt8(RTMP_PACKET_TYPE_VIDEO),
                                                        m_hasAbsTimestamp: 0,
                                                        m_nChannel: 0x04,
                                                        m_nTimeStamp:data.timeStamp,
                                                        m_nInfoField2: self.rtmp.pointee.m_stream_id,
                                                        m_nBodySize: UInt32(length),
                                                        m_nBytesRead: 0,
                                                        m_chunk: nil,
                                                        m_body:mbody.assumingMemoryBound(to: Int8.self)
            )
            
            let packet = UnsafeMutablePointer<RTMPPacket>.allocate(capacity: 1)
            packet.initialize(to: packetRaw)
            if RTMP_SendPacket(self.rtmp,packet, 0) == 0{
                print("send idr error \(packet)")
            }else{
                print("send  \(rawData)")
            }
            packet.deinitialize(count: 1)
            packet.deallocate(capacity: 1)
            mbody.deallocate(bytes:length, alignedTo: MemoryLayout<Int8>.alignment)
        }else {
//            self.setupRTMP()
        }
    }
}
