import Cocoa

class TabsViewController: NSView {
	private var stackView: NSStackView!
	private var scrollView: NSScrollView!
    var tabs: [Tab] = []
    var tabViews: [NSView] = []
    var selectedTabIndex: Int = 0

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
	}

	@discardableResult
	func addTab(with url: URL) -> Tab {
		let newTab = Tab(url: url)
		tabs.append(newTab)

		let tabView = createTabView(for: newTab)
		tabViews.append(tabView)
		stackView.addArrangedSubview(tabView)

		tabView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			tabView.widthAnchor.constraint(greaterThanOrEqualToConstant: 35) // Minimum width for tabs
		])

		selectTab(at: tabs.count - 1)
		updateTabsVisibility()
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

		NSLayoutConstraint.activate([
			faviconImageView.leadingAnchor.constraint(equalTo: tabView.leadingAnchor, constant: 8),
			faviconImageView.centerYAnchor.constraint(equalTo: tabView.centerYAnchor),
			faviconImageView.widthAnchor.constraint(equalToConstant: 16),
			faviconImageView.heightAnchor.constraint(equalToConstant: 16),

			titleLabel.leadingAnchor.constraint(equalTo: faviconImageView.trailingAnchor, constant: 8),
			titleLabel.trailingAnchor.constraint(equalTo: tabView.trailingAnchor, constant: -8),
			titleLabel.centerYAnchor.constraint(equalTo: tabView.centerYAnchor),

			tabView.widthAnchor.constraint(equalToConstant: 200)
		])

		let tabClickGesture = NSClickGestureRecognizer(target: self, action: #selector(tabViewClicked(_:)))
		tabView.addGestureRecognizer(tabClickGesture)

		let closeClickGesture = NSClickGestureRecognizer(target: self, action: #selector(faviconClicked(_:)))
		faviconImageView.addGestureRecognizer(closeClickGesture)

		return tabView
	}

	@objc func faviconClicked(_ gesture: NSClickGestureRecognizer) {
		guard let clickedImageView = gesture.view,
			  let tabView = clickedImageView.superview,
			  let index = tabViews.firstIndex(of: tabView) else { return }

		closeTab(at: index)
	}

    @objc func tabViewClicked(_ gesture: NSClickGestureRecognizer) {
        guard let clickedView = gesture.view,
            let index = tabViews.firstIndex(of: clickedView)
        else { return }
        selectTab(at: index)
    }

    func selectTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
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
		guard index >= 0 && index < tabs.count else { return }

		tabs.remove(at: index)
		let tabView = tabViews.remove(at: index)
		stackView.removeArrangedSubview(tabView)
		tabView.removeFromSuperview()

		if !tabs.isEmpty {
			let newIndex = min(index, tabs.count - 1)
			selectTab(at: newIndex)
		}

		updateTabsVisibility()
		if let mainWindowController = (NSApp.mainWindow?.windowController as? MainWindowController)
		{
			mainWindowController.updateUrlBarPosition()
		}
	}
}
