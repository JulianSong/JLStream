//
//  JLStreamRTMPData.swift
//  JLStream
//
//  Created by Julian.Song on 2017/12/29.
//  Copyright © 2017年 Junliang Song. All rights reserved.
//

import UIKit

class JLStreamRTMPData: NSObject {
    var  NAULData:NSData!
    var timeStamp:UInt32!
    init(NAULData:NSData, timeStamp:UInt32) {
        super.init()
        self.NAULData = NAULData
        self.timeStamp = timeStamp
    }
}
