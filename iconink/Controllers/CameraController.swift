import AVFoundation
import UIKit

class CameraController: NSObject, ObservableObject {
    @Published var isReady = false
    @Published var isAuthorized = false
    let session = AVCaptureSession()
    private var output: AVCapturePhotoOutput?
    private var completion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            startSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.startSession()
                    }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        // Add video input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // Add photo output
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            self.output = output
        }
        
        // Configure for highest quality
        session.sessionPreset = .photo
        
        session.commitConfiguration()
    }
    
    private func startSession() {
        guard !session.isRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isReady = true
            }
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        // Use maxPhotoDimensions instead of deprecated isHighResolutionPhotoEnabled
        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024) // High resolution dimensions
        } else {
            // For older iOS versions
            settings.isHighResolutionPhotoEnabled = true
        }
        
        output?.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion?(nil)
            return
        }
        
        completion?(image)
    }
} 
