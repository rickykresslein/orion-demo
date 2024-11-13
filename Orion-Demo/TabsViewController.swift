import Cocoa

class TabsViewController: NSView {
	private var stackView: NSStackView!
	private var scrollView: NSScrollView!
	var tabs: [Tab] = []
	var tabViews: [NSView] = []
	var selectedTabIndex: Int = 0

	private let minimumTabWidth: CGFloat = 36 // Minimum width to show favicon
	private let preferredTabWidth: CGFloat = 150 // Default/maximum tab width
	private let tabVerticalPadding: CGFloat = 6
	private var tabWidthConstraints: [NSLayoutConstraint] = []
	private var faviconConstraints: [(leading: NSLayoutConstraint, center: NSLayoutConstraint)] = []
	private var titleLabels: [NSTextField] = []
	private var tabBackgroundViews: [TabBackgroundView] = []
	private var faviconToTitleConstraints: [NSLayoutConstraint] = []
	private var titleToTrailingConstraints: [NSLayoutConstraint] = []
	private var tabSeparators: [NSView] = []

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setupNotifications()
		setupViews()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupNotifications()
		setupViews()
	}

	private func setupNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleTabTitleChange(_:)),
			name: .tabTitleDidChange,
			object: nil
		)
	}

	@objc private func handleTabTitleChange(_ notification: Notification) {
		updateTabAppearance()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	private func setupViews() {
		scrollView = NSScrollView()
		scrollView.hasHorizontalScroller = false
		scrollView.hasVerticalScroller = false
		scrollView.autohidesScrollers = true
		scrollView.horizontalScrollElasticity = .none
		scrollView.verticalScrollElasticity = .none
		scrollView.translatesAutoresizingMaskIntoConstraints = false

		// Allow shadow outside of bounds but keep ScrollView in bounds
		scrollView.contentView.wantsLayer = true
		scrollView.contentView.layer?.masksToBounds = true
		scrollView.drawsBackground = false

		stackView = NSStackView()
		stackView.orientation = .horizontal
		stackView.distribution = .fillEqually
		stackView.spacing = 2
		stackView.translatesAutoresizingMaskIntoConstraints = false

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
			stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
			stackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
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

		// Disable default animations
		NSAnimationContext.beginGrouping()
		NSAnimationContext.current.duration = 0
		stackView.addArrangedSubview(tabView)
		stackView.layout()
		NSAnimationContext.endGrouping()

		tabView.wantsLayer = true

		let windowWidth = window?.frame.width ?? 1000
		let extraWidth = windowWidth - 400

		let translateAnimation = CABasicAnimation(keyPath: "transform.translation.x")
		translateAnimation.fromValue = stackView.bounds.width + extraWidth
		translateAnimation.toValue = 0
		translateAnimation.duration = 0.3
		translateAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

		tabView.layer?.transform = CATransform3DMakeTranslation(stackView.bounds.width + extraWidth, 0, 0)

		selectTab(at: tabs.count - 1)
		updateTabsVisibility()
		updateTabWidths()

		tabView.layer?.transform = CATransform3DIdentity
		tabView.layer?.add(translateAnimation, forKey: "slideIn")

		return newTab
	}

	func createTabView(for tab: Tab) -> NSView {
		let tabView = TabView()
		tabView.wantsLayer = true

		let backgroundView = TabBackgroundView()
		backgroundView.translatesAutoresizingMaskIntoConstraints = false
		backgroundView.isActiveTab = false
		tabView.addSubview(backgroundView)

		let separatorView = NSView()
		separatorView.wantsLayer = true
		separatorView.layer?.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor

		let faviconImageView = FaviconImageView()
		faviconImageView.image = tab.favicon ?? NSImage(systemSymbolName: "globe", accessibilityDescription: "Default favicon")
		faviconImageView.imageScaling = .scaleProportionallyDown
		faviconImageView.isEnabled = true

		let titleLabel = NSTextField(labelWithString: tab.title)
		titleLabel.lineBreakMode = .byTruncatingTail
		titleLabel.drawsBackground = false
		titleLabel.isBezeled = false
		titleLabel.isEditable = false

		tabView.addSubview(separatorView)
		tabView.addSubview(faviconImageView)
		tabView.addSubview(titleLabel)

		backgroundView.translatesAutoresizingMaskIntoConstraints = false
		separatorView.translatesAutoresizingMaskIntoConstraints = false
		faviconImageView.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		tabView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			backgroundView.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
			backgroundView.trailingAnchor.constraint(equalTo: tabView.trailingAnchor),
			backgroundView.topAnchor.constraint(equalTo: tabView.topAnchor, constant: tabVerticalPadding),
			backgroundView.bottomAnchor.constraint(equalTo: tabView.bottomAnchor, constant: -tabVerticalPadding),

			separatorView.trailingAnchor.constraint(equalTo: tabView.trailingAnchor),
			separatorView.topAnchor.constraint(equalTo: tabView.topAnchor, constant: tabVerticalPadding + 4),
			separatorView.bottomAnchor.constraint(equalTo: tabView.bottomAnchor, constant: -(tabVerticalPadding + 4)),
			separatorView.widthAnchor.constraint(equalToConstant: 1)
		])

		tabView.onHoverStateChanged = { [weak self, weak backgroundView] isHovered in
			backgroundView?.isHidden = false
			backgroundView?.isHovered = isHovered
			self?.updateTabAppearance()
		}

		// Create both centered and leading constraints for favicon, depending on if text is hidden
		let faviconLeadingConstraint = faviconImageView.leadingAnchor.constraint(equalTo: tabView.leadingAnchor, constant: 8)
		let faviconCenterConstraint = faviconImageView.centerXAnchor.constraint(equalTo: tabView.centerXAnchor)
		faviconCenterConstraint.isActive = false

		let faviconToTitle = faviconImageView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -8)
		let titleToTrailing = titleLabel.trailingAnchor.constraint(equalTo: tabView.trailingAnchor, constant: -8)

		NSLayoutConstraint.activate([
			faviconLeadingConstraint,
			faviconImageView.centerYAnchor.constraint(equalTo: tabView.centerYAnchor),
			faviconImageView.widthAnchor.constraint(equalToConstant: 16),
			faviconImageView.heightAnchor.constraint(equalToConstant: 16),

			titleLabel.centerYAnchor.constraint(equalTo: tabView.centerYAnchor),
			faviconToTitle,
			titleToTrailing
		])

		faviconConstraints.append((leading: faviconLeadingConstraint, center: faviconCenterConstraint))
		faviconToTitleConstraints.append(faviconToTitle)
		titleToTrailingConstraints.append(titleToTrailing)
		titleLabels.append(titleLabel)
		tabBackgroundViews.append(backgroundView)
		tabSeparators.append(separatorView)

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

		let selectedTabDesiredWidth = min(
			calculateIdealTabWidth(for: selectedTabIndex),
			preferredTabWidth
		)

		let remainingWidth = availableWidth - selectedTabDesiredWidth
		let nonSelectedTabCount = tabCount - 1

		var nonSelectedTabWidth = nonSelectedTabCount > 0 ? remainingWidth / nonSelectedTabCount : 0
		nonSelectedTabWidth = min(nonSelectedTabWidth, preferredTabWidth)
		nonSelectedTabWidth = max(nonSelectedTabWidth, minimumTabWidth)

		var totalWidth: CGFloat = 0

		for (i, constraint) in tabWidthConstraints.enumerated() {
			let isSelected = i == selectedTabIndex
			let newTabWidth = isSelected ? selectedTabDesiredWidth : nonSelectedTabWidth

			constraint.constant = newTabWidth
			totalWidth += newTabWidth

			let isCompressed = isSelected ? (newTabWidth < 60) : (newTabWidth <= minimumTabWidth + 10)
			titleLabels[i].isHidden = isCompressed

			faviconConstraints[i].leading.isActive = false
			faviconConstraints[i].center.isActive = false
			faviconToTitleConstraints[i].isActive = false
			titleToTrailingConstraints[i].isActive = false

			if isCompressed {
				// Centered favicon only
				faviconConstraints[i].center.isActive = true
			} else {
				// Leading favicon with title
				faviconConstraints[i].leading.isActive = true
				faviconToTitleConstraints[i].isActive = true
				titleToTrailingConstraints[i].isActive = true
			}
		}

		stackView.frame.size.width = totalWidth
	}

	private func calculateIdealTabWidth(for index: Int) -> CGFloat {
		guard index >= 0 && index < titleLabels.count else {
			return minimumTabWidth
		}

		let label = titleLabels[index]
		let title = label.stringValue

		// Create temporary string to measure text width
		let attributedString = NSAttributedString(string: title, attributes: [
			.font: label.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
		])
		let textWidth = attributedString.size().width

		// Add padding for favicon and spacing
		let totalWidth = textWidth + 45

		return min(totalWidth, preferredTabWidth)
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
		guard !tabs.isEmpty && index >= 0 && index < tabs.count else {
			return
		}
		let oldIndex = selectedTabIndex
		selectedTabIndex = index

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = 0.2
			context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

			// Grow or shrink old selected tab
			if oldIndex >= 0 && oldIndex < tabWidthConstraints.count {
				let oldTabWidth = calculateTabWidthForAnimation(for: oldIndex, isSelected: false)
				tabWidthConstraints[oldIndex].animator().constant = oldTabWidth

				// Update appearance for the old selected tab
				if oldIndex < tabBackgroundViews.count {
					tabBackgroundViews[oldIndex].isActiveTab = false
					tabBackgroundViews[oldIndex].animator().isHidden = true
					titleLabels[oldIndex].textColor = .secondaryLabelColor
				}
			}

			guard index < tabWidthConstraints.count && index < tabBackgroundViews.count else {
				return
			}

			// Grow or shrink new selected tab
			let newTabWidth = calculateTabWidthForAnimation(for: index, isSelected: true)
			tabWidthConstraints[index].animator().constant = newTabWidth

			tabBackgroundViews[index].isActiveTab = true
			tabBackgroundViews[index].animator().isHidden = false
			titleLabels[index].textColor = .labelColor

			for (i, constraint) in tabWidthConstraints.enumerated() {
				if i != index && i != oldIndex {
					let width = calculateTabWidthForAnimation(for: i, isSelected: false)
					constraint.animator().constant = width
				}
			}

			for (i, separator) in tabSeparators.enumerated() {
				let hideSeperator = i == index || i == tabViews.count - 1 || i + 1 == index
				separator.animator().isHidden = hideSeperator
			}

		}) { [weak self] in
			guard let self = self else { return }
			self.updateTabWidths()

			if let mainWindowController = (NSApp.mainWindow?.windowController as? MainWindowController),
			   let contentViewController = mainWindowController.contentViewController as? ViewController
			{
				if !self.tabs.isEmpty, self.tabs.indices.contains(index) {
					contentViewController.setCurrentTab(self.tabs[index])
				}
			}
		}
	}

	private func calculateTabWidthForAnimation(for index: Int, isSelected: Bool) -> CGFloat {
		let availableWidth = bounds.width
		let tabCount = CGFloat(tabs.count)

		if isSelected {
			let selectedTabDesiredWidth = min(
				calculateIdealTabWidth(for: index),
				preferredTabWidth
			)
			return selectedTabDesiredWidth
		} else {
			let selectedTabWidth = min(
				calculateIdealTabWidth(for: selectedTabIndex),
				preferredTabWidth
			)
			let remainingWidth = availableWidth - selectedTabWidth
			let nonSelectedTabCount = tabCount - 1

			var nonSelectedTabWidth = nonSelectedTabCount > 0 ? remainingWidth / nonSelectedTabCount : 0
			nonSelectedTabWidth = min(nonSelectedTabWidth, preferredTabWidth)
			nonSelectedTabWidth = max(nonSelectedTabWidth, minimumTabWidth)

			return nonSelectedTabWidth
		}
	}

	func updateTabAppearance() {
		for (index, tabView) in tabViews.enumerated() {
			let isSelected = index == selectedTabIndex
			let backgroundView = tabBackgroundViews[index]
			let isHovered = (tabView as? TabView)?.isHovered ?? false

			backgroundView.isHidden = false
			backgroundView.isActiveTab = isSelected
			backgroundView.isHovered = isHovered

			// Wait for fade-out animation to complete before hiding
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				if !backgroundView.isActiveTab && !backgroundView.isHovered {
					backgroundView.isHidden = true
				}
			}

			if index < tabSeparators.count {
				let nextTabHovered = tabViews.indices.contains(index + 1) ?
				(tabViews[index + 1] as? TabView)?.isHovered ?? false : false
				let nextTabSelected = (index + 1 == selectedTabIndex)
				let isLastTab = index == tabs.count - 1

				let hideSeparator = isSelected ||
				isHovered ||
				nextTabSelected ||
				nextTabHovered ||
				isLastTab

				NSAnimationContext.runAnimationGroup { context in
					context.duration = 0.3
					tabSeparators[index].animator().alphaValue = hideSeparator ? 0.0 : 1.0
				}
			}

			titleLabels[index].textColor = isSelected ? .labelColor : .secondaryLabelColor

			if let faviconImageView = tabView.subviews[2] as? FaviconImageView,
			   let titleLabel = tabView.subviews.last as? NSTextField {
				faviconImageView.updateFavicon(tabs[index].favicon ??
											   NSImage(systemSymbolName: "globe", accessibilityDescription: "Default favicon"))
				titleLabel.stringValue = tabs[index].title
			}
		}

		updateTabWidths()
	}


	func updateTabsVisibility() {
		scrollView.isHidden = tabs.count <= 1
	}

	func animateTabAddition() {
		NSAnimationContext.runAnimationGroup({ context in
			context.duration = 0.3
			context.allowsImplicitAnimation = true
			context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
			stackView.layoutSubtreeIfNeeded()
		}, completionHandler: nil)
	}

	func closeTab(at index: Int) {
		guard index >= 0 && index < tabs.count,
			  index < tabViews.count,
			  index < tabWidthConstraints.count,
			  index < faviconConstraints.count,
			  index < titleLabels.count,
			  index < tabBackgroundViews.count,
			  index < tabSeparators.count else {
			return
		}

		tabs.remove(at: index)
		let tabView = tabViews.remove(at: index)
		let widthConstraint = tabWidthConstraints.remove(at: index)
		faviconConstraints.remove(at: index)
		faviconToTitleConstraints.remove(at: index)
		titleToTrailingConstraints.remove(at: index)
		titleLabels.remove(at: index)
		tabBackgroundViews.remove(at: index)
		tabSeparators.remove(at: index)

		stackView.removeArrangedSubview(tabView)
		tabView.removeFromSuperview()

		if !tabs.isEmpty {
			if index <= selectedTabIndex {
				selectedTabIndex = max(0, selectedTabIndex - 1)
			}
			selectTab(at: selectedTabIndex)
		} else {
			selectedTabIndex = -1
			// Handle the case when all tabs are closed
			if let mainWindowController = (NSApp.mainWindow?.windowController as? MainWindowController) {
				mainWindowController.updateUrlBarPosition()
				mainWindowController.close()
			}
		}

		NSAnimationContext.runAnimationGroup({ context in
			context.duration = 0.3
			context.allowsImplicitAnimation = true
			context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

			widthConstraint.constant = 0
			tabView.alphaValue = 0

			stackView.layoutSubtreeIfNeeded()

		}) { [weak self] in
			tabView.removeFromSuperview()
			self?.updateTabsVisibility()
			self?.updateTabWidths()
			self?.updateTabAppearance()

			if let mainWindowController = (NSApp.mainWindow?.windowController as? MainWindowController) {
				mainWindowController.updateUrlBarPosition()
			}
		}
	}
}
