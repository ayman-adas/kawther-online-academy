import Flutter
import UIKit
import Security

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    // Register device_id MethodChannel
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.aou.no_screenshot/device_id",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getIosDeviceId" {
        result(self.getOrCreateKeychainDeviceId())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Reads a UUID from Keychain, or generates and stores a new one.
  // Keychain data on iOS persists across app uninstalls/reinstalls.
  private func getOrCreateKeychainDeviceId() -> String {
    let service = "com.aou.no_screenshot"
    let account = "stable_device_id"

    // Try to read existing
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: kCFBooleanTrue!,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
       let data = item as? Data,
       let storedId = String(data: data, encoding: .utf8) {
      return storedId
    }

    // Generate new UUID and store in Keychain
    let newId = UUID().uuidString
    let addQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: newId.data(using: .utf8)!
    ]
    SecItemAdd(addQuery as CFDictionary, nil)
    return newId
  }
}
