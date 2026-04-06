import UIKit
import Flutter
import Firebase
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var screenCaptureChannel: FlutterMethodChannel?
  private var deviceOwnerNameChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FirebaseApp.configure()

//     GMSServices.provideAPIKey("AIzaSyBHqVzwkHddcK1QF4tFIcgAAOOgXjFT8vQ")
    GMSServices.provideAPIKey("AIzaSyCrCWsAC8g6uR1HxVG4ScFzWdpP6V_sJgI")

    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      screenCaptureChannel = FlutterMethodChannel(
        name: "screen_capture",
        binaryMessenger: controller.binaryMessenger
      )
      deviceOwnerNameChannel = FlutterMethodChannel(
        name: "device_owner_name",
        binaryMessenger: controller.binaryMessenger
      )

      deviceOwnerNameChannel?.setMethodCallHandler { [weak self] call, result in
        guard let _ = self else { return }
        if call.method == "getDeviceOwnerName" {
          let deviceName = UIDevice.current.name.trimmingCharacters(in: .whitespacesAndNewlines)
          result(deviceName.isEmpty ? "iPhone" : deviceName)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(screenCaptureChanged),
        name: UIScreen.capturedDidChangeNotification,
        object: nil
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func screenCaptureChanged() {
    let isCaptured = UIScreen.main.isCaptured
    screenCaptureChannel?.invokeMethod(
      "onCaptureChanged",
      arguments: isCaptured
    )
  }
}

