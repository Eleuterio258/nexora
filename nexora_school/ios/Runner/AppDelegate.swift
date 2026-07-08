import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let appInfoChannel = FlutterMethodChannel(
      name: "tech.e258tech.nexora_school/app_info",
      binaryMessenger: controller.binaryMessenger
    )
    appInfoChannel.setMethodCallHandler { call, result in
      if call.method == "getAppVersion" {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        result(version)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
