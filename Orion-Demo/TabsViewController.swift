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
	private var tabBackgroundViews: [NSVisualEffectView] = []

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

		// Allow shadow outside of bounds
		scrollView.contentView.wantsLayer = true
		scrollView.contentView.layer?.masksToBounds = false
		scrollView.drawsBackground = false

		stackView = NSStackView()
		stackView.orientation = .horizontal
		stackView.distribution = .fillEqually
		stackView.spacing = 2
		stackView.translatesAutoresizingMaskIntoConstraints = false

		// Allow shadow outside of bounds
		stackView.wantsLayer = true
		stackView.layer?.masksToBounds = false

		scrollView.documentView = stackView
		addSubview(scrollView)

		// Allow shadow outside of bounds
		wantsLayer = true
		layer?.masksToBounds = false

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

		// Create a shadow around active tab
		let shadowContainer = NSView()
		shadowContainer.wantsLayer = true
		shadowContainer.layer?.shadowColor = NSColor.black.withAlphaComponent(0.6).cgColor
		shadowContainer.layer?.shadowOffset = NSSize(width: 0, height: 0)
		shadowContainer.layer?.shadowRadius = 5
		shadowContainer.layer?.shadowOpacity = 0.2
		shadowContainer.layer?.masksToBounds = false
		// Rasterize to improve performance
		shadowContainer.layer?.shouldRasterize = true
		shadowContainer.layer?.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0

		// Create background view for button effect
		let backgroundView = NSVisualEffectView()
		backgroundView.state = .active
		backgroundView.material = .contentBackground // Maybe .contentBackground
		backgroundView.blendingMode = .withinWindow
		backgroundView.wantsLayer = true
		backgroundView.layer?.cornerRadius = 4
		backgroundView.layer?.cornerCurve = .continuous
		backgroundView.isEmphasized = true
		backgroundView.isHidden = true
		// Rasterize to improve performance
		backgroundView.layer?.shouldRasterize = true
		backgroundView.layer?.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 2.0

		tabView.addSubview(shadowContainer)
		shadowContainer.addSubview(backgroundView)

		let faviconImageView = FaviconImageView()
		faviconImageView.image = tab.favicon ?? NSImage(systemSymbolName: "globe", accessibilityDescription: "Default favicon")
		faviconImageView.imageScaling = .scaleProportionallyDown
		faviconImageView.isEnabled = true

		let titleLabel = NSTextField(labelWithString: tab.title)
		titleLabel.lineBreakMode = .byTruncatingTail
		titleLabel.drawsBackground = false
		titleLabel.isBezeled = false
		titleLabel.isEditable = false

		tabView.addSubview(faviconImageView)
		tabView.addSubview(titleLabel)

		shadowContainer.translatesAutoresizingMaskIntoConstraints = false
		backgroundView.translatesAutoresizingMaskIntoConstraints = false
		faviconImageView.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		tabView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			shadowContainer.leadingAnchor.constraint(equalTo: tabView.leadingAnchor, constant: 4),
			shadowContainer.trailingAnchor.constraint(equalTo: tabView.trailingAnchor, constant: -4),
			shadowContainer.topAnchor.constraint(equalTo: tabView.topAnchor, constant: 2),
			shadowContainer.bottomAnchor.constraint(equalTo: tabView.bottomAnchor, constant: -2)
		])

		NSLayoutConstraint.activate([
			backgroundView.leadingAnchor.constraint(equalTo: tabView.leadingAnchor, constant: 4),
			backgroundView.trailingAnchor.constraint(equalTo: tabView.trailingAnchor, constant: -4),
			backgroundView.topAnchor.constraint(equalTo: tabView.topAnchor, constant: 2),
			backgroundView.bottomAnchor.constraint(equalTo: tabView.bottomAnchor, constant: -2)
		])

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
		tabBackgroundViews.append(backgroundView)

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
			let isSelected = index == selectedTabIndex

			if let shadowContainer = tabBackgroundViews[index].superview {
				shadowContainer.layer?.shadowOpacity = isSelected ? 0.3 : 0
			}
			tabBackgroundViews[index].isHidden = !isSelected

			titleLabels[index].textColor = isSelected ? .labelColor : .secondaryLabelColor

			if let faviconImageView = tabView.subviews[1] as? FaviconImageView,
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
		tabWidthConstraints.remove(at: index)
		faviconConstraints.remove(at: index)
		titleLabels.remove(at: index)
		tabBackgroundViews.remove(at: index)

		stackView.removeArrangedSubview(tabView)
		tabView.removeFromSuperview()

		if !tabs.isEmpty {
			if index <= selectedTabIndex {
				selectedTabIndex = max(0, selectedTabIndex - 1)
			}
			selectTab(at: selectedTabIndex)
		}

		updateTabsVisibility()
		updateTabWidths()
		updateTabAppearance()

		if let mainWindowController = (NSApp.mainWindow?.windowController as? MainWindowController) {
			mainWindowController.updateUrlBarPosition()
		}
	}
}
