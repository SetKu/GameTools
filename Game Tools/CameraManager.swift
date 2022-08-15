//
//  CameraManager.swift
//  Game Tools
//
//  Created by Zachary Morden on 2022-08-14.
//

import Foundation
import AVFoundation
import UIKit

// AVFoundation docs: https://is.gd/yTeDVL

// Initially followed a guide from Raywenderlich to create this manager, but I ended up diverging from their tutorial partly through it.
// Guide: https://is.gd/5xwRTE

final class CameraManager: ObservableObject {
    enum Status {
        case unconfigured, configured, unauthorized, failed
    }
    
    enum CameraError {
        case deniedAuthorization, restrictedAuthorization, unknownAuthorization, cameraUnavailable, cannotAddInput, createCaptureInput(Error), cannotAddOutput
    }
    
    init() { configure() }
    
    func setDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        videoOutput.setSampleBufferDelegate(delegate, queue: outputQueue)
    }
    
    var status = Status.unconfigured
    @Published private(set) var cameraError: CameraError?
    
    private let sessionQueue = DispatchQueue(label: "dev.morden.gametools.camerasession")
    private let outputQueue = DispatchQueue(
        label: "dev.morden.gametools.cameraoutput",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // Session hooks.
    var paused: Bool { !session.isRunning }
    func pause() {
        sessionQueue.async {
            self.session.stopRunning()
        }
    }
    func resume() {
        sessionQueue.async {
            self.session.startRunning()
        }
    }
    
    private func configure() {
        checkPermissions()
        
        sessionQueue.async {
            self.configureCaptureSession()
            self.session.startRunning()
        }
    }
    
    private func configureCaptureSession() {
        guard status == .unconfigured else { return }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInTelephotoCamera, .builtInTripleCamera], mediaType: .video, position: .back)
        
        guard !discovery.devices.isEmpty else {
            status = .failed
            set(.cameraUnavailable)
            return
        }
        
        let device = discovery.devices.first!
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                set(.cannotAddInput)
                status = .failed
                return
            }
        } catch {
            set(.createCaptureInput(error))
            status = .failed
            return
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            let connection = videoOutput.connection(with: .video)
            connection?.videoOrientation = .portrait
            connection?.isEnabled = true
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(orientationChanged),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
        } else {
            set(.cannotAddOutput)
            status = .failed
            return
        }
    }
    
    @objc private func orientationChanged() {
        let connection = videoOutput.connection(with: .video)
        
        switch UIDevice.current.orientation {
        case .unknown:
            break
        case .portrait:
            connection?.videoOrientation = .portrait
            break
        case .portraitUpsideDown:
            connection?.videoOrientation = .portraitUpsideDown
            break
        case .landscapeLeft:
            connection?.videoOrientation = .landscapeLeft
            break
        case .landscapeRight:
            connection?.videoOrientation = .landscapeRight
            break
        default:
            break
        }
    }
    
    private func set(_ error: CameraError?) {
        DispatchQueue.main.async {
            self.cameraError = error
        }
    }
    
    private func checkPermissions() {        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            sessionQueue.suspend()
            
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    self.status = .unauthorized
                    self.set(.deniedAuthorization)
                }
                
                self.sessionQueue.resume()
            }
            
            break
        case .restricted:
            status = .unauthorized
            set(.restrictedAuthorization)
            break
        case .denied:
            status = .unauthorized
            set(.deniedAuthorization)
            break
        case .authorized:
            break
        @unknown default:
            status = .unauthorized
            set(.unknownAuthorization)
        }
    }
}
