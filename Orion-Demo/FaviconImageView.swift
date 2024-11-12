import Cocoa

class FaviconImageView: NSImageView {
	private var originalImage: NSImage?
	private let closeIcon = NSImage(systemSymbolName: "x.square.fill", accessibilityDescription: nil)
	private var trackingArea: NSTrackingArea?
	private var isMouseInside = false
	private var stateCheckTimer: Timer?

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setupNotifications()
		setupStateCheckTimer()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupNotifications()
		setupStateCheckTimer()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
		stateCheckTimer?.invalidate()
	}

	private func setupStateCheckTimer() {
		stateCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
			guard let self = self else { return }
			if self.isMouseInside != NSEvent.mouseInView(self) {
				self.updateImageBasedOnMouseLocation()
			}
		}
	}

	private func setupNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(applicationDidResignActive),
			name: NSApplication.didResignActiveNotification,
			object: nil
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(applicationDidBecomeActive),
			name: NSApplication.didBecomeActiveNotification,
			object: nil
		)
	}

	@objc private func applicationDidResignActive(_ notification: Notification) {
		resetToOriginalState()
	}

	@objc private func applicationDidBecomeActive(_ notification: Notification) {
		updateImageBasedOnMouseLocation()
	}

	private func updateImageBasedOnMouseLocation() {
		if NSEvent.mouseInView(self) {
			isMouseInside = true
			image = closeIcon
			NSCursor.pointingHand.push()
		} else {
			resetToOriginalState()
		}
	}

	private func resetToOriginalState() {
		isMouseInside = false
		if NSCursor.current == NSCursor.pointingHand {
			NSCursor.pop()
		}
		image = originalImage ?? NSImage(systemSymbolName: "globe", accessibilityDescription: "Default favicon")
	}

	func updateFavicon(_ newImage: NSImage?) {
		originalImage = newImage
		if !isMouseInside {
			image = newImage
		}
		needsDisplay = true
	}

	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		updateTrackingArea()
	}

	override func setFrameSize(_ newSize: NSSize) {
		super.setFrameSize(newSize)
		updateTrackingArea()
	}

	private func updateTrackingArea() {
		if let existingTrackingArea = trackingArea {
			removeTrackingArea(existingTrackingArea)
		}

		let newTrackingArea = NSTrackingArea(
			rect: bounds,
			options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
			owner: self,
			userInfo: nil
		)
		addTrackingArea(newTrackingArea)
		trackingArea = newTrackingArea

		if window != nil {
			updateImageBasedOnMouseLocation()
		}
	}

	override func mouseEntered(with event: NSEvent) {
		isMouseInside = true
		NSCursor.pointingHand.push()
		image = closeIcon
	}

	override func mouseExited(with event: NSEvent) {
		resetToOriginalState()
	}

	override func updateTrackingAreas() {
		super.updateTrackingAreas()
		updateTrackingArea()
	}
}

extension NSEvent {
	static func mouseInView(_ view: NSView) -> Bool {
		if let window = view.window {
			let mouseLocation = window.mouseLocationOutsideOfEventStream
			let convertedPoint = view.convert(mouseLocation, from: nil)
			return view.bounds.contains(convertedPoint)
		}
		return false
	}
}
