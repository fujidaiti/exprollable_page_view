import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // TODO; Replace YOUR_API_KEY with your Google Maps API Key
    GMSServices.provideAPIKey("YOUR_API_KEY")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
