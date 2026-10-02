import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // 시안 기준의 콘텐츠 크기. 창을 늘려도 Flutter 쪽 폭은 393으로 유지한다.
    self.setContentSize(NSSize(width: 393, height: 852))
    self.contentMinSize = NSSize(width: 393, height: 640)
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
