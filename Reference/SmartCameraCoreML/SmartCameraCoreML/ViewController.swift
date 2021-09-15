//
//  ViewController.swift
//  SmartCameraCoreML
//
//  Created by Thiago Oliveira on 14/09/21.
//

import AVKit
import UIKit
import Vision

class ViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var firstResultLabel: UILabel!
    @IBOutlet private weak var secondResultLabel: UILabel!
    @IBOutlet private weak var thirdResultLabel: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo

        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }

        captureSession.addInput(input)
        captureSession.startRunning()

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        view.layer.addSublayer(previewLayer)
        previewLayer.frame = mainView.frame

        let dataOutut = AVCaptureVideoDataOutput()
        dataOutut.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutut)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        firstResultLabel.text = "Waiting for object :)"
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        guard let model = try? VNCoreMLModel(for: Resnet50(configuration: MLModelConfiguration()).model) else { return }

        let request = VNCoreMLRequest(model: model) { finishedRequest, error in
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }

            let firstResults = results.prefix(3)

            DispatchQueue.main.async {
                self.firstResultLabel.text = "\(firstResults[0].identifier): \(round(firstResults[0].confidence * 100))%"
                self.secondResultLabel.text = "\(firstResults[1].identifier): \(round(firstResults[1].confidence * 100))%"
                self.thirdResultLabel.text = "\(firstResults[2].identifier): \(round(firstResults[2].confidence * 100))%"
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
