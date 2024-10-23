import Cocoa

class FaviconImageView: NSImageView {
	private var originalImage: NSImage?
	private let closeIcon = NSImage(systemSymbolName: "x.square.fill", accessibilityDescription: nil)

	func updateFavicon(_ newImage: NSImage?) {
		originalImage = newImage
		image = newImage
	}

	override func updateTrackingAreas() {
		super.updateTrackingAreas()

		// Remove existing tracking areas
		for trackingArea in trackingAreas {
			removeTrackingArea(trackingArea)
		}

		// Add new tracking area
		let trackingArea = NSTrackingArea(
			rect: bounds,
			options: [.mouseEnteredAndExited, .activeAlways],
			owner: self,
			userInfo: nil
		)
		addTrackingArea(trackingArea)
	}

	override func mouseEntered(with event: NSEvent) {
		NSCursor.pointingHand.push()
		self.image = closeIcon
	}

	override func mouseExited(with event: NSEvent) {
		NSCursor.pop()
		self.image = originalImage ?? NSImage(systemSymbolName: "globe", accessibilityDescription: "Default favicon")
	}
	}
