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
    var connectButton:UIButton?
    var sendButton:UIButton?
    var tosk:UILabel!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle:nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoCapturer = JLStreamVideoCapturer.init(withView: self.view)
        self.videoCapturer?.encoder.rtmp.delegate = self
        do{
            let label = UILabel.init()
            label.backgroundColor = .black
            label.alpha = 0;
            label.textAlignment = .center
            label.textColor = .white
            self.view.addSubview(label);
            label.center = self.view.center
            label.layer.cornerRadius = 4
            label.clipsToBounds = true
            self.tosk = label
        }
        
        do{
            let button = UIButton()
            button.setTitle("Connect", for:.normal)
            button.setTitle("Connecting...", for: .disabled)
            button.setTitle("Connecting", for: .selected)
            self.view .addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant:10).isActive = true
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            button.rightAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -5).isActive = true
            button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10).isActive = true
            button.backgroundColor = UIColor.orange
            button.layer.cornerRadius = 8
            button.addTarget(self, action: #selector(ViewController.connectAtion(sender:)), for: UIControlEvents.touchUpInside)
            self.connectButton = button
        }
        
        do{
            let button = UIButton()
            button.setTitle("Start Push", for:.normal)
            button.setTitle("Eed Push", for: .selected)
            self.view .addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.leftAnchor.constraint(equalTo: self.view.centerXAnchor, constant:5).isActive = true
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            button.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -10).isActive = true
            button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10).isActive = true
            button.backgroundColor = UIColor.gray
            button.isEnabled = false
            button.layer.cornerRadius = 8
            button.addTarget(self, action: #selector(ViewController.sendAtion(sender:)), for: UIControlEvents.touchUpInside)
            self.sendButton = button
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.videoCapturer?.start()
    }
    
    @objc func connectAtion(sender:UIButton) {
        if sender.isSelected {
            return
        }
        sender.isEnabled = false
        self.videoCapturer?.encoder.rtmp.crete("rtmp://192.168.31.209:1935/rtmplive/room")
    }

    @objc func sendAtion(sender:UIButton) {
        
        if sender.isSelected {
            self.videoCapturer?.encoder.rtmp.stopPush()
            sender.backgroundColor = UIColor.blue
            sender.isSelected = false
            return;
        }
        
        if (self.videoCapturer?.encoder.rtmp.startPush())! {
            sender.backgroundColor = UIColor.red
            sender.isSelected = true
        }
    }
    
    func showToask(_ text:String)  {
        self.tosk.text = text
        self.tosk.font = UIFont .systemFont(ofSize: 25)
        self.tosk.sizeToFit()
        self.tosk.font = UIFont .systemFont(ofSize: 18)
        self.tosk.center = self.view.center
        UIView.animate(withDuration: 0.3) {
            self.tosk.alpha = 1;
        }
        
        UIView.animate(withDuration: 0.3, delay: 2.3, options: .curveEaseIn, animations: {
            self.tosk.alpha = 0;
        }) { (sucess) in
            
        }
    }
}

extension ViewController:JLStreamRTMPEngineDelegate {
    func RTMPEngine(_ RTMPEngine: JLStreamRTMPEngine, didConnect success: Bool, error: String?) {
        if success {
            DispatchQueue.main.async {
                self.connectButton?.backgroundColor = UIColor.gray
                self.connectButton?.isEnabled = true
                self.connectButton?.isSelected = true
                self.sendButton?.isEnabled = true
                self.sendButton?.backgroundColor = UIColor.blue
            }
        }else{
            DispatchQueue.main.async {
                self.connectButton?.isEnabled = true
                self.showToask(error!)
            }
        }
    }
}

