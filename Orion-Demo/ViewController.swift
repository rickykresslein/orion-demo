import Cocoa
import WebKit

class ViewController: NSViewController, WKNavigationDelegate {

	@IBOutlet var webView: WKWebView!
	weak var mainWindowController: MainWindowController?
	var currentTab: Tab?

	override func viewDidLoad() {
		super.viewDidLoad()

		let webConfiguration = WKWebViewConfiguration()
		webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
		webView.autoresizingMask = [.width, .height]
		webView.navigationDelegate = self
		view.addSubview(webView)
	}

	func setCurrentTab(_ tab: Tab) {
		currentTab = tab

		if let oldWebView = view.subviews.first as? WKWebView {
			oldWebView.removeFromSuperview()
		}

		tab.webView.frame = view.bounds
		tab.webView.autoresizingMask = [.width, .height]
		tab.webView.navigationDelegate = self
		view.addSubview(tab.webView)

		if let url = tab.webView.url?.absoluteString {
			mainWindowController?.updateUrlField(with: url)
		}
	}

	func loadWebPage(url: URL) {
		let request = URLRequest(url: url)
		if let currentTab = currentTab {
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
			mainWindowController?.updateUrlField(with: url)
			currentTab?.title = webView.title ?? ""
			mainWindowController?.tabsViewController?.updateTabAppearance()

			// Get favicon
			webView.evaluateJavaScript("var link = document.querySelector('link[rel~=\"icon\"]'); link ? link.href : '';") { (result, error) in
				if let faviconURLString = result as? String, let faviconURL = URL(string: faviconURLString) {
					self.loadFavicon(from: faviconURL)
				} else {
					if let defaultFaviconURL = URL(string: "\(webView.url?.scheme ?? "https")://\(webView.url?.host ?? "")/favicon.ico") {
						self.loadFavicon(from: defaultFaviconURL)
					} else {
						self.mainWindowController?.tabsViewController?.updateTabAppearance()
					}
				}
			}
		}

		mainWindowController?.updateBackButtonState()
	}

	private func loadFavicon(from url: URL) {
		URLSession.shared.dataTask(with: url) { (data, response, error) in
			if let data = data, let image = NSImage(data: data) {
				DispatchQueue.main.async {
					self.currentTab?.favicon = image
					self.mainWindowController?.tabsViewController?.updateTabAppearance()
				}
			}
		}.resume()
	}

}
