import Cocoa
import WebKit

class ViewController: NSViewController, WKNavigationDelegate {

	@IBOutlet var webView: WKWebView!
	weak var mainWindowController: MainWindowController?
	var currentTab: Tab?

	private var observingWebViews: Set<WKWebView> = []

	override func viewDidLoad() {
		super.viewDidLoad()

		let webConfiguration = WKWebViewConfiguration()
		webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
		webView.autoresizingMask = [.width, .height]
		webView.navigationDelegate = self
		view.addSubview(webView)

		addWebViewObserver(webView)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleTabTitleChange(_:)),
			name: .tabTitleDidChange,
			object: nil
		)
	}

	@objc private func handleTabTitleChange(_ notification: Notification) {
		if let _ = notification.object as? Tab {
			mainWindowController?.tabsViewController?.updateTabAppearance()
		}
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "title" {
			if let webView = object as? WKWebView {
				currentTab?.title = webView.title ?? ""
				mainWindowController?.tabsViewController?.updateTabAppearance()
			}
		} else if keyPath == "canGoBack" {
			DispatchQueue.main.async {
				self.mainWindowController?.updateBackButtonState()
			}
        }
	}

	func setCurrentTab(_ tab: Tab) {
		currentTab = tab

		if let oldWebView = view.subviews.first as? WKWebView {
			removeWebViewObserver(oldWebView)
			oldWebView.removeFromSuperview()
		}

		currentTab = tab

		tab.webView.frame = view.bounds
		tab.webView.autoresizingMask = [.width, .height]
		tab.webView.navigationDelegate = self
		view.addSubview(tab.webView)

		addWebViewObserver(tab.webView)

		if let url = tab.webView.url?.absoluteString {
			mainWindowController?.updateUrlField(with: url)
		}

		mainWindowController?.updateBackButtonState()
	}

	func loadWebPage(url: URL) {
		let request = URLRequest(url: url)
		if let currentTab = currentTab {
			currentTab.favicon = NSImage(systemSymbolName: "globe", accessibilityDescription: "Default favicon")
			mainWindowController?.tabsViewController?.updateTabAppearance()
			currentTab.webView.load(request)
		} else {
			webView.load(request)
		}
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		print("Failed to load: \(error.localizedDescription)")
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		print("Navigation failed: \(error.localizedDescription)")
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		if let url = webView.url?.absoluteString {
			// Update URL field only for current tab
			if webView == currentTab?.webView {
				mainWindowController?.updateUrlField(with: url)
				mainWindowController?.updateBackButtonState()
			}

			// Load favicon regardless of whether this is the current tab
			webView.evaluateJavaScript("var link = document.querySelector('link[rel~=\"icon\"]'); link ? link.href : '';") { [weak self] (result, error) in
				if let faviconURLString = result as? String,
				   let faviconURL = URL(string: faviconURLString) {
					self?.loadFavicon(from: faviconURL, for: webView)
				} else if let defaultFaviconURL = URL(string: "\(webView.url?.scheme ?? "https")://\(webView.url?.host ?? "")/favicon.ico") {
					self?.loadFavicon(from: defaultFaviconURL, for: webView)
				}
			}
		}
	}

	func webView(_ webView: WKWebView, didChangeTitle title: String?) {
		currentTab?.title = title ?? ""
		mainWindowController?.tabsViewController?.updateTabAppearance()
	}

	private func loadFavicon(from url: URL, for webView: WKWebView) {
		URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
			if let data = data,
			   let image = NSImage(data: data),
			   let tab = self?.mainWindowController?.tabsViewController?.tabs.first(where: { $0.webView == webView }) {
				DispatchQueue.main.async {
					tab.favicon = image
					self?.mainWindowController?.tabsViewController?.updateTabAppearance()
				}
			}
		}.resume()
	}

	private func addWebViewObserver(_ webView: WKWebView) {
		if !observingWebViews.contains(webView) {
			webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
			observingWebViews.insert(webView)
		}
	}

	private func removeWebViewObserver(_ webView: WKWebView) {
		if observingWebViews.contains(webView) {
			webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack))
			observingWebViews.remove(webView)
		}
	}

	deinit {
		for webView in observingWebViews {
			removeWebViewObserver(webView)
		}
		NotificationCenter.default.removeObserver(self)
	}
}
