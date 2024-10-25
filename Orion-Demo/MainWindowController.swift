import Cocoa
import WebKit

class MainWindowController: NSWindowController {
	@IBOutlet var toolbarView: NSToolbar!
	@IBOutlet var backButton: NSToolbarItem!
	@IBOutlet var urlField: NSToolbarItem!
	@IBOutlet weak var tabsView: NSToolbarItem!
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
		if tabsViewController?.tabs.count ?? 0 <= 1 {
			// Center the URL bar
			urlField.visibilityPriority = .high
			toolbarView.centeredItemIdentifier = urlField.itemIdentifier
		} else {
			// Move URL bar to the left
			urlField.visibilityPriority = .high
			if let index = toolbarView.items.firstIndex(of: urlField) {
				toolbarView.removeItem(at: index)
			}
			toolbarView.insertItem(withItemIdentifier: urlField.itemIdentifier, at: 2)
			toolbarView.centeredItemIdentifier = nil
		}
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
			if !urlString.starts(with: "http://") && !urlString.starts(with: "https://") {
				urlString = "https://\(urlString)"
			}
			if let url = URL(string: urlString),
			   let contentViewController = contentViewController as? ViewController {
				contentViewController.loadWebPage(url: url)
				contentViewController.currentTab?.url = url
				tabsViewController?.updateTabAppearance()
			}
		}
	}

	func updateUrlField(with urlString: String) {
		urlTextField?.stringValue = urlString
		urlTextField?.updateLockIcon(for: urlString)
	}

	@objc func goBack(_ sender: Any) {
		if let contentViewController = contentViewController as? ViewController {
			contentViewController.webView?.goBack()
		}
	}

	func setupBackButton() {
		backButton.isEnabled = false
		backButton.target = self
		backButton.action = #selector(goBack(_:))
	}

	func updateBackButtonState() {
		if let contentViewController = contentViewController as? ViewController {
			backButton.isEnabled = contentViewController.webView?.canGoBack ?? false
		}
	}
}

class FaviconURLCell: NSTextFieldCell {
	var favicon: NSImage?

	override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
		let textRect = adjustedFrame(toVerticallyCenterText: cellFrame)
		super.drawInterior(withFrame: textRect, in: controlView)

		if let favicon = favicon {
			let imageSize = NSSize(width: 16, height: 16)
			let imageRect = NSRect(x: cellFrame.origin.x, y: cellFrame.origin.y + (cellFrame.size.height - imageSize.height) / 2, width: imageSize.width, height: imageSize.height)
			favicon.draw(in: imageRect)
		}
	}

	override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
		let textRect = adjustedFrame(toVerticallyCenterText: rect)
		super.select(withFrame: textRect, in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
	}

	override func drawFocusRingMask(withFrame cellFrame: NSRect, in controlView: NSView) {
		let textRect = adjustedFrame(toVerticallyCenterText: cellFrame)
		super.drawFocusRingMask(withFrame: textRect, in: controlView)
	}

	override func focusRingMaskBounds(forFrame cellFrame: NSRect, in controlView: NSView) -> NSRect {
		return adjustedFrame(toVerticallyCenterText: cellFrame)
	}

	private func adjustedFrame(toVerticallyCenterText rect: NSRect) -> NSRect {
		var titleRect = super.titleRect(forBounds: rect)
		titleRect.origin.x += (favicon != nil) ? 20 : 0
		titleRect.size.width -= (favicon != nil) ? 20 : 0
		return titleRect
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
