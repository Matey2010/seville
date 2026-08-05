import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    guard
      let configuredIcon = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconFile") as? String,
      !configuredIcon.isEmpty
    else {
      return
    }
    let iconName = (configuredIcon as NSString).deletingPathExtension
    guard
      let iconURL = Bundle.main.url(forResource: iconName, withExtension: "icns"),
      let icon = NSImage(contentsOf: iconURL)
    else {
      return
    }
    DispatchQueue.main.async {
      NSApp.applicationIconImage = icon
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
