import Cocoa

class TabsViewController: NSView {
	private var stackView: NSStackView!
	private var scrollView: NSScrollView!
	var tabs: [Tab] = []
	var tabViews: [NSView] = []
	var selectedTabIndex: Int = 0

	private let minimumTabWidth: CGFloat = 36 // Minimum width to show favicon
	private let preferredTabWidth: CGFloat = 200 // Default/maximum tab width
	private var tabWidthConstraints: [NSLayoutConstraint] = []
	private var faviconConstraints: [(leading: NSLayoutConstraint, center: NSLayoutConstraint)] = []
	private var titleLabels: [NSTextField] = []

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setupViews()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupViews()
	}

	private func setupViews() {
		scrollView = NSScrollView()
		scrollView.hasHorizontalScroller = true
		scrollView.hasVerticalScroller = false
		scrollView.autohidesScrollers = true
		scrollView.horizontalScrollElasticity = .none
		scrollView.translatesAutoresizingMaskIntoConstraints = false

		stackView = NSStackView()
		stackView.orientation = .horizontal
		stackView.distribution = .fillEqually
		stackView.spacing = 2
		stackView.translatesAutoresizingMaskIntoConstraints = false

		scrollView.documentView = stackView
		addSubview(scrollView)

		NSLayoutConstraint.activate([
			scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
			scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
			scrollView.topAnchor.constraint(equalTo: topAnchor),
			scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

			stackView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor),
			stackView.bottomAnchor.constraint(equalTo: scrollView.contentView.bottomAnchor),
			stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
		])

		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(viewFrameDidChange),
		                                       name: NSView.frameDidChangeNotification,
		                                       object: self)
	}

	@discardableResult
	func addTab(with url: URL) -> Tab {
		let newTab = Tab(url: url)
		tabs.append(newTab)

		let tabView = createTabView(for: newTab)
		tabViews.append(tabView)
		stackView.addArrangedSubview(tabView)

		selectTab(at: tabs.count - 1)
		updateTabsVisibility()
		updateTabWidths()
		animateTabAddition()

		return newTab
	}

	func createTabView(for tab: Tab) -> NSView {
		let tabView = NSView()
		tabView.wantsLayer = true
		tabView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

		let faviconImageView = FaviconImageView()
		faviconImageView.image = tab.favicon ?? NSImage(systemSymbolName: "globe", accessibilityDescription: "Default favicon")
		faviconImageView.imageScaling = .scaleProportionallyDown
		faviconImageView.isEnabled = true

		let titleLabel = NSTextField(labelWithString: tab.title)
		titleLabel.lineBreakMode = .byTruncatingTail

		tabView.addSubview(faviconImageView)
		tabView.addSubview(titleLabel)

		faviconImageView.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		tabView.translatesAutoresizingMaskIntoConstraints = false

		// Create both centered and leading constraints for favicon, depending on if text is hidden
		let faviconLeadingConstraint = faviconImageView.leadingAnchor.constraint(equalTo: tabView.leadingAnchor, constant: 8)
		let faviconCenterConstraint = faviconImageView.centerXAnchor.constraint(equalTo: tabView.centerXAnchor)
		faviconCenterConstraint.isActive = false

		NSLayoutConstraint.activate([
			faviconImageView.leadingAnchor.constraint(equalTo: tabView.leadingAnchor, constant: 8),
			faviconImageView.centerYAnchor.constraint(equalTo: tabView.centerYAnchor),
			faviconImageView.widthAnchor.constraint(equalToConstant: 16),
			faviconImageView.heightAnchor.constraint(equalToConstant: 16),

			titleLabel.leadingAnchor.constraint(equalTo: faviconImageView.trailingAnchor, constant: 8),
			titleLabel.trailingAnchor.constraint(equalTo: tabView.trailingAnchor, constant: -8),
			titleLabel.centerYAnchor.constraint(equalTo: tabView.centerYAnchor)
		])

		faviconConstraints.append((leading: faviconLeadingConstraint, center: faviconCenterConstraint))
		titleLabels.append(titleLabel)

		let widthConstraint = tabView.widthAnchor.constraint(equalToConstant: preferredTabWidth)
		widthConstraint.isActive = true
		tabWidthConstraints.append(widthConstraint)

		let tabClickGesture = NSClickGestureRecognizer(target: self, action: #selector(tabViewClicked(_:)))
		tabView.addGestureRecognizer(tabClickGesture)

		let closeClickGesture = NSClickGestureRecognizer(target: self, action: #selector(faviconClicked(_:)))
		faviconImageView.addGestureRecognizer(closeClickGesture)

		return tabView
	}

	@objc private func viewFrameDidChange() {
		updateTabWidths()
	}

	private func updateTabWidths() {
		guard !tabs.isEmpty else {
			return
		}

		let availableWidth = bounds.width
		let tabCount = CGFloat(tabs.count)

		var newTabWidth = min(preferredTabWidth, availableWidth / tabCount)
		newTabWidth = max(newTabWidth, minimumTabWidth)
		for constraint in tabWidthConstraints {
			constraint.constant = newTabWidth
		}

		for i in 0..<tabViews.count {
			let isCompressed = newTabWidth <= minimumTabWidth + 10
			titleLabels[i].isHidden = isCompressed

			// Toggle between centered and leading constraints
			faviconConstraints[i].leading.isActive = !isCompressed
			faviconConstraints[i].center.isActive = isCompressed
		}

		let totalWidth = newTabWidth * tabCount
		stackView.frame.size.width = totalWidth
	}

	@objc func faviconClicked(_ gesture: NSClickGestureRecognizer) {
		guard let clickedImageView = gesture.view,
		      let tabView = clickedImageView.superview,
		      let index = tabViews.firstIndex(of: tabView)
		else {
			return
		}

		closeTab(at: index)
	}

	@objc func tabViewClicked(_ gesture: NSClickGestureRecognizer) {
		guard let clickedView = gesture.view,
		      let index = tabViews.firstIndex(of: clickedView)
		else {
			return
		}
		selectTab(at: index)
	}

	func selectTab(at index: Int) {
		guard index >= 0 && index < tabs.count else {
			return
		}
		selectedTabIndex = index
		updateTabAppearance()

		if let mainWindowController = (NSApp.mainWindow?.windowController as? MainWindowController),
		   let contentViewController = mainWindowController.contentViewController
		   as? ViewController
		{
			contentViewController.setCurrentTab(tabs[index])
		}
	}

	func updateTabAppearance() {
		for (index, tabView) in tabViews.enumerated() {
			tabView.layer?.backgroundColor =
				index == selectedTabIndex
					? NSColor.selectedControlColor.cgColor : NSColor.windowBackgroundColor.cgColor

			if let faviconImageView = tabView.subviews.first as? FaviconImageView,
			   let titleLabel = tabView.subviews.last as? NSTextField
			{
				faviconImageView.updateFavicon(tabs[index].favicon ?? NSImage(systemSymbolName: "globe", accessibilityDescription: "Default favicon"))
				titleLabel.stringValue = tabs[index].title
			}
		}
	}

	func updateTabsVisibility() {
		scrollView.isHidden = tabs.count <= 1
	}

	func animateTabAddition() {
		NSAnimationContext.runAnimationGroup({ context in
			context.duration = 0.3
			context.allowsImplicitAnimation = true
			stackView.layoutSubtreeIfNeeded()
		}, completionHandler: nil)
	}

	func closeTab(at index: Int) {
		guard index >= 0 && index < tabs.count else {
			return
		}

		tabs.remove(at: index)
		let tabView = tabViews.remove(at: index)

		if index < tabWidthConstraints.count {
			tabWidthConstraints.remove(at: index)
			faviconConstraints.remove(at: index)
			titleLabels.remove(at: index)
		}

		stackView.removeArrangedSubview(tabView)
		tabView.removeFromSuperview()

		if !tabs.isEmpty {
			let newIndex = min(index, tabs.count - 1)
			selectTab(at: newIndex)
		}

		updateTabsVisibility()
		updateTabWidths()
		if let mainWindowController = (NSApp.mainWindow?.windowController as? MainWindowController) {
			mainWindowController.updateUrlBarPosition()
		}
	}
}
