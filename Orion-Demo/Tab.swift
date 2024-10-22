import Cocoa
import WebKit

class Tab {
    var url: URL
    var title: String
    var favicon: NSImage?
    var webView: WKWebView

    init(url: URL, title: String = "", favicon: NSImage? = nil) {
        self.url = url
        self.title = title
        self.favicon = favicon

        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView.load(URLRequest(url: url))
    }
}
