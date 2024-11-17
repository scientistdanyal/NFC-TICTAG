import Flutter
import UIKit
import MessageUI

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
    }

  private var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up the method channel
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: "com.example.sms", binaryMessenger: controller.binaryMessenger)
    methodChannel?.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call: call, result: result)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "sendSm`s" {
      guard let args = call.arguments as? [String: Any],
            let phoneNumber = args["phoneNumber"] as? String,
            let message = args["message"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
        return
      }
      
      if MFMessageComposeViewController.canSendText() {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        composeVC.recipients = [phoneNumber]
        composeVC.body = message
        UIApplication.shared.keyWindow?.rootViewController?.present(composeVC, animated: true, completion: nil)
        result("SMS sent")
      } else {
        result(FlutterError(code: "SMS_NOT_AVAILABLE", message: "SMS services are not available", details: nil))
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  func messageComposeController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    controller.dismiss(animated: true, completion: nil)
  }
}
