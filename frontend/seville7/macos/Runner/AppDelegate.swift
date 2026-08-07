import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    applyConfiguredAppName()

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

  private func applyConfiguredAppName() {
    guard
      let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
      !appName.isEmpty
    else {
      return
    }

    if let applicationMenuItem = NSApp.mainMenu?.items.first {
      applicationMenuItem.title = appName
      applicationMenuItem.submenu?.title = appName
      applicationMenuItem.submenu?.items.forEach { item in
        switch item.action {
        case #selector(NSApplication.orderFrontStandardAboutPanel(_:)):
          item.title = "About \(appName)"
        case #selector(NSApplication.hide(_:)):
          item.title = "Hide \(appName)"
        case #selector(NSApplication.terminate(_:)):
          item.title = "Quit \(appName)"
        default:
          break
        }
      }
    }

    NSApp.windows.forEach { window in
      if window is MainFlutterWindow {
        window.title = appName
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
