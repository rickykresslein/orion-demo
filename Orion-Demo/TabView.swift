import Cocoa

class TabView: NSView {
	private var trackingArea: NSTrackingArea?
	var isHovered = false {
		didSet {
			onHoverStateChanged?(isHovered)
		}
	}
	var onHoverStateChanged: ((Bool) -> Void)?

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		setupView()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupView()
	}

	private func setupView() {
		wantsLayer = true
		updateTrackingAreas()
	}

	override func updateTrackingAreas() {
		super.updateTrackingAreas()

		if let existingTrackingArea = trackingArea {
			removeTrackingArea(existingTrackingArea)
		}

		let options: NSTrackingArea.Options = [
			.mouseEnteredAndExited,
			.activeAlways,
			.inVisibleRect
		]

		trackingArea = NSTrackingArea(
			rect: bounds,
			options: options,
			owner: self,
			userInfo: nil
		)

		if let trackingArea = trackingArea {
			addTrackingArea(trackingArea)
		}

		if let window = window {
			let mouseLocation = window.mouseLocationOutsideOfEventStream
			let convertedPoint = convert(mouseLocation, from: nil)
			let shouldBeHovered = bounds.contains(convertedPoint)
			if isHovered != shouldBeHovered {
				isHovered = shouldBeHovered
			}
		}
	}

	override func mouseEntered(with event: NSEvent) {
		super.mouseEntered(with: event)
		isHovered = true
	}

	override func mouseExited(with event: NSEvent) {
		super.mouseExited(with: event)
		isHovered = false
	}

	// Manual check to eliminate leftover highlights
	func checkHoverState() {
		if let window = window {
			let mouseLocation = window.mouseLocationOutsideOfEventStream
			let convertedPoint = convert(mouseLocation, from: nil)
			let shouldBeHovered = bounds.contains(convertedPoint)
			if isHovered != shouldBeHovered {
				isHovered = shouldBeHovered
			}
		}
	}
}
