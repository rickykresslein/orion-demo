import Cocoa
import WebKit

class MainWindowController: NSWindowController {
	@IBOutlet var toolbarView: NSToolbar!
	@IBOutlet var backButton: NSToolbarItem!
	@IBOutlet var urlField: NSToolbarItem!
	@IBOutlet var tabsView: NSToolbarItem!
	@IBOutlet var addTabButton: NSToolbarItem!

	var urlTextField: URLTextField?
	var tabsViewController: TabsViewController?

	private let textFieldHeight: CGFloat = 30
	private let tabsViewHeight: CGFloat = 42

	override func windowDidLoad() {
		super.windowDidLoad()

		if let window = window {
			let desiredSize = NSSize(width: 1512, height: 982)
			window.minSize = NSSize(width: 450, height: 300)

			let screenFrame = NSScreen.main?.visibleFrame ?? .zero
			let origin = NSPoint(
				x: screenFrame.midX - desiredSize.width / 2,
				y: screenFrame.midY - desiredSize.height / 2
			)

			let newFrame = NSRect(origin: origin, size: desiredSize)
			window.setFrame(newFrame, display: true, animate: false)
		}

		window?.toolbarStyle = .unified
		if let contentViewController = contentViewController as? ViewController {
			contentViewController.mainWindowController = self
		}

		setupUrlField()
		setupBackButton()
		setupTabsViewController()
		setupAddTabButton()

		addNewTab(self)
		updateUrlBarPosition()

		backButton.visibilityPriority = .low
		urlField.visibilityPriority = .high
		tabsView.visibilityPriority = .high
		addTabButton.visibilityPriority = .low
	}

	func setupTabsViewController() {
		tabsViewController = TabsViewController(frame: .zero)
		tabsViewController?.translatesAutoresizingMaskIntoConstraints = false
		tabsView.view = tabsViewController

		if let tabsViewController = tabsViewController {
			NSLayoutConstraint.activate([
				tabsViewController.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
				tabsViewController.heightAnchor.constraint(equalToConstant: tabsViewHeight)
			])
		}
	}

	func setupAddTabButton() {
		addTabButton.isEnabled = true
		addTabButton.target = self
		addTabButton.action = #selector(addNewTab(_:))
	}

	@IBAction func addNewTab(_ sender: Any) {
		if let url = URL(string: "https://www.kagi.com") {
			if let newTab = tabsViewController?.addTab(with: url) {
				if let contentViewController = contentViewController as? ViewController {
					contentViewController.setCurrentTab(newTab)
				}
			}
		}
		updateUrlBarPosition()
	}

	func updateUrlBarPosition() {
		NSAnimationContext.runAnimationGroup({ context in
			context.duration = 0.3
			context.allowsImplicitAnimation = true

			if tabsViewController?.tabs.count ?? 0 <= 1 {
				// Center the URL bar
				urlField.visibilityPriority = .high
				toolbarView.centeredItemIdentifier = urlField.itemIdentifier
			} else {
				// Move URL bar to the left
				urlField.visibilityPriority = .high
				toolbarView.centeredItemIdentifier = nil
			}

			self.window?.layoutIfNeeded()
		}, completionHandler: nil)
	}

	func setupUrlField() {
		urlTextField = URLTextField()
		urlTextField?.delegate = self
		urlTextField?.target = self
		urlTextField?.action = #selector(urlFieldChanged(_:))
		urlField.view = urlTextField

		// Size constraints
		urlTextField?.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			urlTextField!.heightAnchor.constraint(equalToConstant: textFieldHeight),
			urlTextField!.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
			urlTextField!.leadingAnchor.constraint(equalTo: urlField.view!.leadingAnchor),
			urlTextField!.trailingAnchor.constraint(equalTo: urlField.view!.trailingAnchor),
			urlTextField!.topAnchor.constraint(equalTo: urlField.view!.topAnchor),
			urlTextField!.bottomAnchor.constraint(equalTo: urlField.view!.bottomAnchor)
		])
	}

	@objc func urlFieldChanged(_ sender: Any) {
		if var urlString = urlTextField?.stringValue {
			if !urlString.contains("://") {
				urlString = "https://\(urlString)"
				urlTextField?.stringValue = urlString
			}
			if let url = URL(string: urlString),
			   let contentViewController = contentViewController as? ViewController
			{
				contentViewController.loadWebPage(url: url)
				contentViewController.currentTab?.url = url
				tabsViewController?.updateTabAppearance()

				// Deselect text field to make it clear URL is loading
				window?.makeFirstResponder(nil)
			}
		}
	}

	func updateUrlField(with urlString: String) {
		urlTextField?.stringValue = urlString
		urlTextField?.updateLockIcon(for: urlString)
	}

	func setupBackButton() {
		backButton.isEnabled = false
		backButton.target = self
		backButton.action = #selector(goBack(_:))
	}

	func updateBackButtonState() {
		if let contentViewController = contentViewController as? ViewController,
		   let currentWebView = contentViewController.currentTab?.webView
		{
			backButton.isEnabled = currentWebView.canGoBack
		} else {
			backButton.isEnabled = false
		}
	}

	@objc func goBack(_ sender: Any) {
		if let contentViewController = contentViewController as? ViewController,
		   let currentWebView = contentViewController.currentTab?.webView
		{
			currentWebView.goBack()
		}
	}
}

extension MainWindowController: NSTextFieldDelegate {
	func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		if commandSelector == #selector(NSResponder.insertNewline(_:)) {
			urlFieldChanged(control)
			return true
		}
		return false
	}
}

// Implement keyboard shortcuts for closing and adding tabs
extension MainWindowController {
	override func responds(to aSelector: Selector!) -> Bool {
		if aSelector == #selector(closeCurrentTab(_:)) {
			return true
		}
		return super.responds(to: aSelector)
	}

	override func performKeyEquivalent(with event: NSEvent) -> Bool {
		if event.type == .keyDown && event.modifierFlags.contains(.command) {
			switch event.charactersIgnoringModifiers {
			case "w":
				if event.modifierFlags.contains(.shift) {
					window?.close()
				} else {
					closeCurrentTab(nil)
				}
				return true
			case "t":
				newTab(nil)
				return true
			default:
				break
			}
		}
		return super.performKeyEquivalent(with: event)
	}

	@objc func closeCurrentTab(_ sender: Any?) {
		// If only one tab exists (not showing tabs) close window
		if tabsViewController?.tabs.count ?? 0 <= 1 {
			window?.close()
			return
		}

		// Otherwise close just the selected tab
		if let index = tabsViewController?.selectedTabIndex {
			tabsViewController?.closeTab(at: index)
		}
	}

	@objc func newTab(_ sender: Any?) {
		addNewTab(self)
	}
}
