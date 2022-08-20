//
//  CameraObserver.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-14.
//

import SwiftUI
import CoreGraphics
import AVFoundation

final class CameraObserver: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var liveImage: CGImage?
    private let manager = CameraManager()
    @Published var active = true {
        didSet {
            if active && manager.paused {
                manager.resume()
            } else if !active && !manager.paused {
                manager.pause()
            }
        }
    }
    
    override private init() {
        super.init()
        manager.setDelegate(self)
    }
    
    static let shared = CameraObserver()
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let buffer = sampleBuffer.imageBuffer {
            DispatchQueue.main.async {
                let ci = CIImage(cvImageBuffer: buffer)
                let cg = CIContext().createCGImage(ci, from: ci.extent)
                self.liveImage = cg
            }
        }
    }
}
