import Cocoa
import WebKit

class Tab {
	static let defaultTitle = String(repeating: " ", count: 35)

	var url: URL
	var title: String
	var favicon: NSImage?
	var webView: WKWebView
	var titleObserver: NSKeyValueObservation?

	init(url: URL, title: String = Tab.defaultTitle, favicon: NSImage? = nil) {
		self.url = url
		self.title = title
		self.favicon = favicon

		let configuration = WKWebViewConfiguration()
		self.webView = WKWebView(frame: .zero, configuration: configuration)

		self.titleObserver = self.webView.observe(\.title) { [weak self] webView, _ in
			self?.title = webView.title ?? Tab.defaultTitle
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
