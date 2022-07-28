
import UIKit
import AVFoundation

@objc(CodeScanner) class CodeScanner : CDVPlugin {

  var command: CDVInvokedUrlCommand?
  var controller: QRScannerController?


  @objc(start:)
  func start(command: CDVInvokedUrlCommand) {


    self.command = command;
    let controller = QRScannerController()
    self.controller = controller;
    controller.setModule(module: self);

    self.viewController.show(controller, sender: self);
  
  }

  @objc(scan:) 
  func scan(command: CDVInvokedUrlCommand) {
    self.command = command;
  }

  @objc(stop:)
  func stop(command: CDVInvokedUrlCommand) {
    controller!.dismiss(animated: false);
    self.command = command;
    self.returnResult("")
  }

  @objc(returnResult:)
  func returnResult(_ result: String) {

    let pluginResult = CDVPluginResult(
      status: CDVCommandStatus_OK,
      messageAs: result
    )

    self.returnResponse(pluginResult!);

  }

  @objc(returnError:)
  func returnError(_ err: String) {
      
    self.controller!.dismiss(animated: false)

    let pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR,
      messageAs: err
    )

    self.returnResponse(pluginResult!);
    print("Error:", err);
  }

  @objc(returnResponse:)
  func returnResponse(_ result: CDVPluginResult) {

    self.commandDelegate.run(inBackground: {
      self.commandDelegate!.send(
        result,
        callbackId: self.command!.callbackId!
      );
    });
  }
}


class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var module: CodeScanner!
    var closeButton: UIButton!
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    
    
    @objc func closeButtonClicked(_ sender: AnyObject?) {
      self.dismiss(animated: false);
      module!.returnError("CANCELLED");
    }

    func setModule(module: CodeScanner) {
      self.module = module;
    }

    @objc override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // create UI
        /// main
        let screenRect = UIScreen.main.bounds
        self.view.frame = screenRect

        
        /// close button
        let buttonLengthWidth: Double = 60;
        
        closeButton = UIButton(type: .system)
        closeButton.setTitle("X", for: .normal)
        closeButton.setTitleColor(.gray, for: .normal)
        closeButton.backgroundColor = .white
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        closeButton.frame = CGRect(
            x: (screenRect.width - buttonLengthWidth) / 2,
            y: screenRect.height - buttonLengthWidth - 20,
            width: buttonLengthWidth,
            height: buttonLengthWidth
        )
        
        closeButton.layer.cornerRadius = buttonLengthWidth / 2
        closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside);

        // Do any additional setup after loading the view.
        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .back)

        guard let captureDevice = deviceDiscoverySession.devices.first else {
            self.module!.returnError("No camera detected");
            return
        }

        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)

            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            captureMetadataOutput.metadataObjectTypes = [
                AVMetadataObject.ObjectType.qr,
                AVMetadataObject.ObjectType.upce,
                AVMetadataObject.ObjectType.ean13,
                AVMetadataObject.ObjectType.ean8,
            ]
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture.
            captureSession.startRunning()
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()

            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
                view.bringSubview(toFront: closeButton)
            }
            
            module!.returnResult("");

        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            // print(error)
            module!.returnError(error.localizedDescription);
            return
        }
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }

        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        
        // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
        let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
        qrCodeFrameView?.frame = barCodeObject!.bounds

        if metadataObj.stringValue != nil {
          module!.returnResult(metadataObj.stringValue!);
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

