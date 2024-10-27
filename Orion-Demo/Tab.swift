import Cocoa
import WebKit

class Tab {
    var url: URL
    var title: String
    var favicon: NSImage?
    var webView: WKWebView
	var titleObserver: NSKeyValueObservation?

    init(url: URL, title: String = "", favicon: NSImage? = nil) {
        self.url = url
        self.title = title
        self.favicon = favicon

        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: configuration)

		self.titleObserver = self.webView.observe(\.title) { [weak self] webView, change in
			self?.title = webView.title ?? ""
			NotificationCenter.default.post(name: .tabTitleDidChange, object: self)
		}

        self.webView.load(URLRequest(url: url))
    }

	deinit {
		titleObserver?.invalidate()
	}
}

extension Notification.Name {
	static let tabTitleDidChange = Notification.Name("tabTitleDidChange")
	static let tabFaviconDidChange = Notification.Name("tabFaviconDidChange")
}
