//
//  ViewController.swift
//  JLStream
//
//  Created by Julian.Song on 2017/12/16.
//  Copyright © 2017年 Junliang Song. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var videoCapturer:JLStreamVideoCapturer?
    let rn:JLStreamRTMPEngine = JLStreamRTMPEngine.init()
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoCapturer = JLStreamVideoCapturer.init(withView: self.view)
        let button = UIButton()
        button.setTitle("Connect", for:.normal)
        self.view .addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 200).isActive = true
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10).isActive = true
        button.backgroundColor = UIColor.orange
        button.addTarget(self, action: #selector(ViewController.connectAtion), for: UIControlEvents.touchUpInside)
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.videoCapturer?.start()
    }
    
    @objc func connectAtion(){
        self.videoCapturer?.encoder.rtmp.crete()
        while true{
            autoreleasepool(invoking: { () -> Swift.Void in
                let intvar:[Int8] = [1,2,3,4,5,6,7,8]
                var data = NSMutableData(bytes: intvar, length: intvar.count)
                for i in 0...2000{
                    data.append(intvar, length: intvar.count)
                }
                self.videoCapturer?.encoder.rtmp.send(data, isKeyFrame: false, timeStamp:0)
//                data.mutableBytes.deallocate(bytes:data.length, alignedTo: MemoryLayout<Int8>.alignment)
            })
        }
        
    }

}

